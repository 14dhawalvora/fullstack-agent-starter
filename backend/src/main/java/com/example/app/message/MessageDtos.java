package com.example.app.message;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

import java.time.Instant;

/** Request/response shapes. Entities never leave the service layer. */
public final class MessageDtos {

    private MessageDtos() {
    }

    public record CreateMessageRequest(@NotBlank @Size(max = 500) String content) {
    }

    public record MessageResponse(Long id, String content, Instant createdAt) {
        static MessageResponse from(Message m) {
            return new MessageResponse(m.getId(), m.getContent(), m.getCreatedAt());
        }
    }
}
