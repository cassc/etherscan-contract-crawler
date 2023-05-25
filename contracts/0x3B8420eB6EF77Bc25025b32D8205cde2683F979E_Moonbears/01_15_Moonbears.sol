//SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

//         :::   :::    ::::::::   ::::::::  ::::    ::: :::::::::  ::::::::::     :::     :::::::::   :::::::: 
//       :+:+: :+:+:  :+:    :+: :+:    :+: :+:+:   :+: :+:    :+: :+:          :+: :+:   :+:    :+: :+:    :+: 
//     +:+ +:+:+ +:+ +:+    +:+ +:+    +:+ :+:+:+  +:+ +:+    +:+ +:+         +:+   +:+  +:+    +:+ +:+         
//    +#+  +:+  +#+ +#+    +:+ +#+    +:+ +#+ +:+ +#+ +#++:++#+  +#++:++#   +#++:++#++: +#++:++#:  +#++:++#++   
//   +#+       +#+ +#+    +#+ +#+    +#+ +#+  +#+#+# +#+    +#+ +#+        +#+     +#+ +#+    +#+        +#+    
//  #+#       #+# #+#    #+# #+#    #+# #+#   #+#+# #+#    #+# #+#        #+#     #+# #+#    #+# #+#    #+#     
// ###       ###  ########   ########  ###    #### #########  ########## ###     ### ###    ###  ########       

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "./NonblockingReceiver.sol";

contract Moonbears is Ownable, ERC721, NonblockingReceiver {
    string private baseURI;
    uint256 public nextTokenId;
    uint256 MAX_MINT;
    uint256 PRICE;

    uint8 MAX_PER_TX = 5;

    uint gasForDestinationLzReceive = 350000;
    bool public isSaleActive = false;
    uint8 private devMints;

    constructor(
        string memory baseURI_, 
        address _layerZeroEndpoint,
        uint256 _startToken,
        uint256 _maxMint,
        uint256 _price,
        uint8 _devMints
    )
    ERC721("Moonbears", "MB") {
        baseURI = baseURI_;
        endpoint = ILayerZeroEndpoint(_layerZeroEndpoint);
        nextTokenId = _startToken;
        MAX_MINT = _maxMint;
        PRICE = _price;
        devMints = _devMints;
    }
    
    modifier callerIsUser() {
        require(tx.origin == msg.sender, "MB: Contract calls not allowed");
        _;
    }

    function mint(uint8 numTokens) external payable callerIsUser {
        require(isSaleActive, "MB: Sale not started");
        require(numTokens <= MAX_PER_TX, "MB: Max 5 NFTs per transaction");
        require(nextTokenId + numTokens <= MAX_MINT, "MB: Mint exceeds supply");
        require(msg.value >= price(numTokens), "MB: Value insufficient");
        for (uint8 i = 0; i < numTokens; i++) {
            _safeMint(msg.sender, ++nextTokenId);
        }
    }

    function devMint() external onlyOwner {
        require(nextTokenId + devMints <= MAX_MINT, "MB: Mint exceeds supply");
        require(devMints > 0, "MB: Already minted");
        for (uint8 i = 0; i < devMints; i++) {
            _safeMint(msg.sender, ++nextTokenId);
        }
        devMints = 0;
    }

    function price(uint8 numTokens) private view returns (uint256) {
        return PRICE * numTokens;
    }

    function setPrice(uint256 _newPrice) external onlyOwner {
        PRICE = _newPrice;
    }

    function setMaxPerTx(uint8 _maxPerTx) external onlyOwner {
        MAX_PER_TX = _maxPerTx;
    }

    function toggleSaleStatus() external onlyOwner {
        isSaleActive = !isSaleActive;
    }

    function traverseChains(uint16 _chainId, uint tokenId) public payable {
        require(msg.sender == ownerOf(tokenId), "MB: You must own the token to traverse");
        require(trustedRemoteLookup[_chainId].length > 0, "MB: This chain is currently unavailable for travel");
        _burn(tokenId);
        bytes memory payload = abi.encode(msg.sender, tokenId);
        uint16 version = 1;
        bytes memory adapterParams = abi.encodePacked(version, gasForDestinationLzReceive);
        (uint messageFee, ) = endpoint.estimateFees(_chainId, address(this), payload, false, adapterParams);
        require(msg.value >= messageFee, "MB: msg.value not enough to cover messageFee. Send gas for message fees");
        endpoint.send{value: msg.value}(
            _chainId,
            trustedRemoteLookup[_chainId],
            payload,
            payable(msg.sender),
            address(0x0),
            adapterParams
        );
    }

    function setBaseURI(string memory URI) external onlyOwner {
        baseURI = URI;
    }

    function withdrawAll() external payable onlyOwner {
        require(payable(_msgSender()).send(address(this).balance), "MB: Failed to withdraw Ether");
    }
    
    function setGasForDestinationLzReceive(uint newVal) external onlyOwner {
        gasForDestinationLzReceive = newVal;
    }
    
    function _LzReceive(uint16 _srcChainId, bytes memory _srcAddress, uint64 _nonce, bytes memory _payload) override internal {
        (address toAddr, uint tokenId) = abi.decode(_payload, (address, uint));
        _safeMint(toAddr, tokenId);
    }

    function _baseURI() override internal view returns (string memory) {
        return baseURI;
    }
    
}