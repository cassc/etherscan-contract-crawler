// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

abstract contract PausableTopic {
    mapping(uint8 => bool) public _pausableTopics;

    error TopicPaused();
    error TopicNotPaused();

    modifier whenPaused(uint8 topic) {
        if (!_pausableTopics[topic]) revert TopicNotPaused();
        _;
    }

    modifier whenNotPaused(uint8 topic) {
        if (_pausableTopics[topic]) revert TopicPaused();
        _;
    }

    function isPaused(uint8 topic) public view returns(bool) {
        return _pausableTopics[topic];
    }
}