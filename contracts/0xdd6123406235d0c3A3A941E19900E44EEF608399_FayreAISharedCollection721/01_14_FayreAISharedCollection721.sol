// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";

contract FayreAISharedCollection721 is Ownable, ERC721Enumerable, ERC721Burnable {
    struct MintTokenData {
        address recipient;
        uint256 amount;
    }

    event Mint(address indexed owner, uint256 indexed tokenId, string tokenURI);

    uint256 public price;
    uint256 public maxSupply;
    address public treasuryAddress;
    mapping(address => uint256) public remainingFreeMints;
    mapping(address => bool) public isValidator;

    uint256 private _currentTokenId;
    mapping(uint256 => string) private _tokenURI;
    string private _contractURI;
    
    function setPrice(uint256 newPrice) external onlyOwner {
        price = newPrice;
    }

    function setMaxSupply(uint256 newMaxSupply) external onlyOwner {
        maxSupply = newMaxSupply;
    }

    function setTreasury(address newTreasuryAddress) external onlyOwner {
        require(newTreasuryAddress != address(0), "Cannot set address 0");

        treasuryAddress = newTreasuryAddress;
    }

    function setContractURI(string calldata newContractURI) external onlyOwner {
        _contractURI = newContractURI;
    }

    function changeAddressIsValidator(address validatorAddress, bool state) external onlyOwner {
        isValidator[validatorAddress] = state;
    }

    function setFreeMinters(MintTokenData[] calldata freeMintersData) external onlyOwner {
        for (uint256 i = 0; i < freeMintersData.length; i++)
            remainingFreeMints[freeMintersData[i].recipient] = freeMintersData[i].amount;
    }

    function batchMintWithSignedMessage(string[] memory tokensURIs, uint8 v, bytes32 r, bytes32 s) external payable {
        for (uint256 i = 0; i < tokensURIs.length; i++)
            _mintNFT(msg.sender, tokensURIs[i]);

        _verifySignedMessage(tokensURIs, v, r, s);

        if (price > 0)
            _processLiquidity(tokensURIs.length);
    }

    function contractURI() public view returns (string memory) {
        return _contractURI;
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        return _tokenURI[tokenId];
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC721Enumerable) returns(bool) {
        return interfaceId == type(ERC721Enumerable).interfaceId || interfaceId == type(ERC721Burnable).interfaceId || super.supportsInterface(interfaceId);
    }

    function _verifySignedMessage(string[] memory tokensURIs, uint8 v, bytes32 r, bytes32 s) internal view {
        bytes32 generatedHash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", keccak256(abi.encode(tokensURIs))));
        
        address signer = ecrecover(generatedHash, v, r, s);

        require(isValidator[signer], "Invalid signed message");
    }

    function _processLiquidity(uint256 tokensAmount) internal {
        uint256 tokensToPayAmount = tokensAmount;

        if (remainingFreeMints[msg.sender] > 0) {
            if (tokensToPayAmount >= remainingFreeMints[msg.sender]) {
                tokensToPayAmount -= remainingFreeMints[msg.sender];

                remainingFreeMints[msg.sender] = 0;
            } else {
                tokensToPayAmount = 0;

                remainingFreeMints[msg.sender] -= tokensToPayAmount;
            } 
        }

        if (tokensToPayAmount == 0)
            return;

        uint256 liquidityToPayAmount = price * tokensToPayAmount;

        require(msg.value >= liquidityToPayAmount, "Insufficient liquidity");

        (bool liquiditySendToTreasurySuccess, ) = treasuryAddress.call{value: liquidityToPayAmount }("");

        require(liquiditySendToTreasurySuccess, "Unable to send liquidity to treasury");

        uint256 valueToRefund = msg.value - liquidityToPayAmount;

        if (valueToRefund > 0) {
            (bool refundSuccess, ) = msg.sender.call{value: valueToRefund }("");

            require(refundSuccess, "Unable to refund extra liquidity");
        }
    }

    function _mintNFT(address recipient, string memory tokenURI_) internal returns(uint256) {
        if (maxSupply > 0)
            require(_currentTokenId + 1 <= maxSupply, "Max supply reached");

        uint256 tokenId = _currentTokenId++;

        _mint(recipient, tokenId);

        _tokenURI[tokenId] = tokenURI_;

        emit Mint(recipient, tokenId, tokenURI_);

        return tokenId;
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal override(ERC721, ERC721Enumerable) {
        ERC721Enumerable._beforeTokenTransfer(from , to, tokenId);
    }

    constructor(uint256 maxSupply_, uint256 price_, address treasuryAddress_, address validator_, string memory name_, string memory symbol_, string memory contractURI_) ERC721(name_, symbol_) {
        maxSupply = maxSupply_;
        price = price_;
        treasuryAddress = treasuryAddress_;
        isValidator[validator_] = true;
        _contractURI = contractURI_;
    }
}