// SPDX-License-Identifier: MIT-open-group
pragma solidity ^0.8.16;

import "test/contract-mocks/publicStaking/BaseMock.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

contract ReentrantLoopEthCollectorAccount is BaseMock {
    uint256 internal _tokenID;

    constructor() {}

    receive() external payable virtual override {
        collectEth(_tokenID);
    }

    function setTokenID(uint256 tokenID_) public {
        _tokenID = tokenID_;
    }
}

contract ReentrantFiniteEthCollectorAccount is BaseMock {
    uint256 internal _tokenID;
    uint256 internal _count = 0;

    constructor() {}

    receive() external payable virtual override {
        if (_count < 2) {
            _count++;
            collectEth(_tokenID);
        } else {
            return;
        }
    }

    function setTokenID(uint256 tokenID_) public {
        _tokenID = tokenID_;
    }
}

contract ReentrantLoopBurnAccount is BaseMock {
    uint256 internal _tokenID;

    constructor() {}

    receive() external payable virtual override {
        burn(_tokenID);
    }

    function setTokenID(uint256 tokenID_) public {
        _tokenID = tokenID_;
    }
}

contract ReentrantFiniteBurnAccount is BaseMock {
    uint256 internal _tokenID;
    uint256 internal _count = 0;

    constructor() {}

    receive() external payable virtual override {
        if (_count < 2) {
            _count++;
            burn(_tokenID);
        } else {
            return;
        }
    }

    function setTokenID(uint256 tokenID_) public {
        _tokenID = tokenID_;
    }
}

contract ERC721ReceiverAccount is BaseMock, IERC721Receiver {
    constructor() {}

    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external pure override returns (bytes4) {
        operator;
        from;
        tokenId;
        data;
        return bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"));
    }
}

contract ReentrantLoopBurnERC721ReceiverAccount is BaseMock, IERC721Receiver {
    uint256 internal _tokenId;

    constructor() {}

    receive() external payable virtual override {
        publicStaking.burn(_tokenId);
    }

    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external override returns (bytes4) {
        operator;
        from;
        data;
        _tokenId = tokenId;
        publicStaking.burn(tokenId);
        return bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"));
    }
}

contract ReentrantFiniteBurnERC721ReceiverAccount is BaseMock, IERC721Receiver {
    uint256 internal _tokenId;
    uint256 internal _count = 0;

    constructor() {}

    receive() external payable virtual override {
        publicStaking.burn(_tokenId);
    }

    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external override returns (bytes4) {
        operator;
        from;
        tokenId;
        data;
        if (_count < 2) {
            _count++;
            _tokenId = tokenId;
            publicStaking.burn(tokenId);
        }

        return bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"));
    }
}

contract ReentrantLoopCollectEthERC721ReceiverAccount is BaseMock, IERC721Receiver {
    uint256 internal _tokenId;

    constructor() {}

    receive() external payable virtual override {
        publicStaking.collectEth(_tokenId);
    }

    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external override returns (bytes4) {
        operator;
        from;
        data;
        _tokenId = tokenId;
        publicStaking.collectEth(tokenId);
        return bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"));
    }
}