package com.example.app.message;

import com.example.app.message.MessageDtos.CreateMessageRequest;
import com.example.app.message.MessageDtos.MessageResponse;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.data.domain.PageRequest;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Service
public class MessageService {

    static final int MAX_LIMIT = 100;
    private static final Logger log = LoggerFactory.getLogger(MessageService.class);

    private final MessageRepository messages;

    public MessageService(MessageRepository messages) {
        this.messages = messages;
    }

    @Transactional(readOnly = true)
    public List<MessageResponse> latest(int limit) {
        int size = Math.max(1, Math.min(MAX_LIMIT, limit));
        return messages.findAllByOrderByIdDesc(PageRequest.of(0, size)).stream()
                .map(MessageResponse::from)
                .toList();
    }

    @Transactional
    public MessageResponse create(CreateMessageRequest request) {
        Message saved = messages.save(new Message(request.content().trim()));
        log.info("Message {} created", saved.getId());
        return MessageResponse.from(saved);
    }
}
