// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract VapeMonkeys is ERC721A, Ownable {
    using Strings for uint256;

    uint256 public constant MAX_SUPPLY = 10000;
    uint256 public constant MAX_BATCH_SIZE = 8;
    uint256 public constant PRICE = .05 ether;

    string public baseTokenUri;

    uint256 public constant MAX_GIVEAWAY_SUPPLY = 500;
    uint256 public giveawaySupply;

    bool public isRevealed;
    bool public publicSale;
    bool public pause;

    constructor() ERC721A("Vape Monkeys", "VM") {}

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "Cannot be called by a contract");
        _;
    }

    function mint(uint256 _quantity) external payable callerIsUser {
        require(pause == false, "Minting paused");
        require(publicSale, "Public sale not yet started.");
        require((totalSupply() + _quantity) < MAX_SUPPLY, "Beyond max Supply");
        require(msg.value >= (PRICE * _quantity), "Insuficient value");
        require(
            _quantity <= MAX_BATCH_SIZE,
            "Attempting to mint more than maximum allowed batch size"
        );

        _safeMint(msg.sender, _quantity);
    }

    function mintGiveaway(
        uint256 _quantity,
        address recepient
    ) external payable callerIsUser {
        require((totalSupply() + _quantity) <= MAX_SUPPLY, "Beyond max supply");
        require(
            (giveawaySupply + _quantity) <= MAX_GIVEAWAY_SUPPLY,
            "Beyond giveaway supply"
        );

        giveawaySupply = giveawaySupply + _quantity;

        _safeMint(recepient, _quantity);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenUri;
    }

    //return uri for certain token
    function tokenURI(
        uint256 tokenId
    ) public view virtual override returns (string memory) {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        //string memory baseURI = _baseURI();
        return
            bytes(baseTokenUri).length > 0
                ? string(
                    abi.encodePacked(baseTokenUri, tokenId.toString(), ".json")
                )
                : "";
    }

    /// @dev walletOf() function shouldn't be called on-chain due to gas consumption
    function walletOf() external view returns (uint256[] memory) {
        address _owner = msg.sender;
        uint256 numberOfOwnedNFT = balanceOf(_owner);
        uint256[] memory ownerIds = new uint256[](numberOfOwnedNFT);

        for (uint256 index = 0; index < numberOfOwnedNFT; index++) {
            ownerIds[index] = tokenOfOwnerByIndex(_owner, index);
        }

        return ownerIds;
    }

    function setTokenUri(string memory _baseTokenUri) external onlyOwner {
        baseTokenUri = _baseTokenUri;
    }

    function togglePause() external onlyOwner {
        pause = !pause;
    }

    function togglePublicSale() external onlyOwner {
        publicSale = !publicSale;
    }

    function toggleReveal() external onlyOwner {
        isRevealed = !isRevealed;
    }

    function withdraw() external onlyOwner {
        uint256 withdrawAmount_A = (address(this).balance * 80) / 100;
        uint256 withdrawAmount_B = address(this).balance - withdrawAmount_A;

        payable(0x8c8c1fCb8560601a0B6D4728BcF816f3118295d9).transfer(
            withdrawAmount_A
        );
        payable(0x93BbD169503F19CdF0c8324eD3C03655ae305Eaf).transfer(
            withdrawAmount_B
        );
    }

    function getMintPrice() external pure returns (uint256) {
        return PRICE;
    }
}