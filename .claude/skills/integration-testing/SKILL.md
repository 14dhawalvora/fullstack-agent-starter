---
name: integration-testing
description: Write Spring Boot integration tests (JUnit 5 + MockMvc + real in-memory database) that call REST endpoints end to end through controller, service, repository and DB - success, validation, not-found, conflicts, side effects and concurrent requests. Use when adding or changing an endpoint.
---

# Integration testing (API + database)

Pattern to copy: `backend/src/test/java/com/example/app/message/MessageApiTest.java`.

## Setup
```java
@SpringBootTest
@AutoConfigureMockMvc
@Transactional          // each test rolls back -> tests stay independent
class OrderApiTest {
    @Autowired MockMvc mvc;
    @Autowired OrderRepository orders;   // arrange data / assert DB state directly

    @Test
    void createReturns201() throws Exception {
        mvc.perform(post("/api/orders").contentType(MediaType.APPLICATION_JSON)
                        .content("{\"sku\":\"A1\",\"quantity\":2}"))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.quantity").value(2));
        assertThat(orders.count()).isEqualTo(1);
    }
}
```
Tests use in-memory H2 (`src/test/resources/application.yml`), never the dev DB file.

## Cases for every endpoint
**Rule: test the success path AND every error status documented for the endpoint in `docs/API.md`, one test per status.** This is required, never trimmed for time; manual curl checks don't count. Name tests after the case, e.g. `deleteUnknownIdReturns404`, and finish with a table `endpoint | status | test name`.

| Case | Expect |
|---|---|
| Happy path | 200/201 + body fields + DB rows |
| Each validation rule (missing, blank, too long, out of range, wrong format) | 400 + `$.errors.<field>` |
| Malformed JSON | 400 |
| Unknown id / reference | 404 |
| Business conflict (duplicate, state not allowed) | 409/422 + `$.detail` |
| Auth (if the feature has it) | 401 not logged in, 403 wrong role or not owner |
| **Failure leaves no partial writes** | DB unchanged after an error response |
| Repeated identical request (if the API promises it is safe to retry) | same response, no duplicate rows |

## Concurrent requests (when the feature updates shared state)
Real commits are needed, so **no** `@Transactional` on this test class; clean up in `@AfterEach`.
```java
int threads = 10;
ExecutorService pool = Executors.newFixedThreadPool(threads);
CountDownLatch start = new CountDownLatch(1);
List<Future<Integer>> codes = new ArrayList<>();
for (int i = 0; i < threads; i++) {
    codes.add(pool.submit(() -> {
        start.await();
        return mvc.perform(post("/api/...").contentType(MediaType.APPLICATION_JSON).content(body))
                  .andReturn().getResponse().getStatus();
    }));
}
start.countDown();
// assert: number of successes is what the rules allow, and the stored state is consistent
```

## Run
`cd backend && mvn -q test -Dtest=OrderApiTest`. Failure details: `backend/target/surefire-reports/*.txt`.
