package com.example.app.message;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.transaction.annotation.Transactional;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@SpringBootTest
@AutoConfigureMockMvc
@Transactional // each test rolls back
class MessageApiTest {

    @Autowired
    MockMvc mvc;

    @Test
    void createdMessagesComeBackNewestFirst() throws Exception {
        create("first");
        create("second");

        mvc.perform(get("/api/messages/latest").param("limit", "2"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$[0].content").value("second"))
                .andExpect(jsonPath("$[1].content").value("first"));
    }

    @Test
    void blankContentIsRejected() throws Exception {
        mvc.perform(post("/api/messages").contentType(MediaType.APPLICATION_JSON).content("{\"content\":\" \"}"))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.errors.content").exists());
    }

    private void create(String content) throws Exception {
        mvc.perform(post("/api/messages")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"content\":\"" + content + "\"}"))
                .andExpect(status().isCreated());
    }
}
