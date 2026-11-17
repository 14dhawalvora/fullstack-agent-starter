---
name: unit-testing
description: Write fast JUnit 5 unit tests for backend business logic (services, validators, calculators) with no Spring context and no database - plain objects or Mockito mocks. Use when adding or changing a business rule in a service or helper class.
---

# Unit testing (backend logic)

Unit tests check **one class's rules** in milliseconds. No `@SpringBootTest`, no DB, no HTTP.
Endpoints and DB behaviour belong in the `integration-testing` skill.

## Pattern
```java
class PriceCalculatorTest {

    private final PriceCalculator calc = new PriceCalculator();

    @Test
    void appliesDiscountAboveThreshold() {
        assertThat(calc.total(10_000, 2)).isEqualTo(19_000);
    }

    @ParameterizedTest
    @CsvSource({"0, 0", "1, 1", "9999, 9999"})
    void boundaryValues(long input, long expected) {
        assertThat(calc.total(input, 1)).isEqualTo(expected);
    }

    @Test
    void rejectsNegativeQuantity() {
        assertThatThrownBy(() -> calc.total(100, -1))
                .isInstanceOf(IllegalArgumentException.class)
                .hasMessageContaining("quantity");
    }
}
```

Service with dependencies -> mock them:
```java
@ExtendWith(MockitoExtension.class)
class OrderServiceTest {
    @Mock OrderRepository orders;
    @InjectMocks OrderService service;

    @Test
    void notFoundWhenMissing() {
        when(orders.findById(42L)).thenReturn(Optional.empty());
        assertThatThrownBy(() -> service.get(42L)).isInstanceOf(NotFoundException.class);
        verify(orders, never()).save(any());
    }
}
```

## What to cover for each rule
- Happy path with a realistic value.
- **Boundaries**: 0, 1, max, max+1, empty, null, exactly-at-limit.
- **Invalid input**: each rejection path asserts the exception type and message.
- **No side effect on failure**: `verify(repo, never()).save(any())`.
- Precision-sensitive values (amounts, rates, dates): assert exact values, not "close enough".

## Rules
- One behaviour per test; name it as a sentence (`rejectsNegativeQuantity`).
- Arrange / act / assert; no logic (loops, ifs) inside tests beyond setup.
- AssertJ (`assertThat`) for readable failures. Both JUnit 5 and Mockito come with `spring-boot-starter-test`.
- Put tests in the same package as the class under test, under `src/test/java`.

## Run
`cd backend && mvn -q test -Dtest=PriceCalculatorTest`
