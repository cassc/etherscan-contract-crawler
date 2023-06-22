// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract BastardPenguins is ERC721, Ownable {
    using Strings for uint256;

    uint256 public itemPrice = 0.02 ether;

    bool public isSaleActive = false;
    uint256 public constant totalTokenToMint = 9999;
    uint256 public purchasedPenguins = 0;

    uint256 private startingIpfsId;

    uint256 private _lastIpfsId;

    uint256 public REVEAL_TIMESTAMP = block.timestamp + 30 days;

    // Optional mapping for token URIs
    mapping(uint256 => uint256) private _tokenURIs;

    // Base URI
    string public baseURI = "";

    constructor() ERC721("Bastard Penguins", "BP") {}

    /////////////////////////////////////////
    // Action methods: Write Contract Part //
    /////////////////////////////////////////

    //purchase multiple penguins at once
    function purchasePenguins(uint256 _howMany) external payable {
        require(_howMany > 0, "Minimum 1 tokens need to be minted");
        require(
            _howMany <= penguinsRemainingToBeMinted(),
            "Purchase amount is greater than the token available"
        );
        require(isSaleActive, "Sale is not active");
        require(_howMany <= 20, "max 20 penguins at once");
        require(itemPrice * _howMany == msg.value, "Insufficient ETH to mint");
        for (uint256 i = 0; i < _howMany; i++) {
            _mintPenguin(_msgSender());
        }
    }

    function setRevealTimestamp(uint256 revealTimeStamp) external onlyOwner {
        REVEAL_TIMESTAMP = revealTimeStamp;
    }

    function _mintPenguin(address _to) private {
        if (purchasedPenguins == 0) {
            _lastIpfsId = random(
                1,
                totalTokenToMint,
                uint256(uint160(address(_msgSender()))) + 1
            );
            startingIpfsId = _lastIpfsId;
        } else {
            _lastIpfsId = getIpfsIdToMint();
        }
        purchasedPenguins++;
        require(!_exists(purchasedPenguins), "Mint: Token already exist.");
        _mint(_to, purchasedPenguins);
        _tokenURIs[purchasedPenguins] = _lastIpfsId;
    }

    // Gift NFT to people
    function gift(address[] calldata to) external onlyOwner {
        require(
            to.length <= penguinsRemainingToBeMinted(),
            "gift amount is greater than the token available"
        );

        for (uint256 i = 0; i < to.length; i++) {
            _mintPenguin(to[i]);
        }
    }

    // Reserve NFT for owner
    function reserveNFT(uint256 _howMany, address _sendNftsTo)
        external
        onlyOwner
    {
        require(
            _howMany <= penguinsRemainingToBeMinted(),
            "reserve amount is greater than the token available"
        );

        for (uint256 i = 0; i < _howMany; i++) {
            _mintPenguin(_sendNftsTo);
        }
    }

    // Change Price in case of ETH price changes too much
    function setPrice(uint256 _newPrice) external onlyOwner {
        itemPrice = _newPrice;
    }

    function burn(uint256 _tokenId) external {
        require(_exists(_tokenId), "Burn: token does not exist.");
        require(
            ownerOf(_tokenId) == _msgSender(),
            "Burn: caller is not token owner."
        );
        _burn(_tokenId);
    }

    function stopSale() external onlyOwner {
        isSaleActive = false;
    }

    function startSale() external onlyOwner {
        isSaleActive = true;
    }

    function withdrawETH() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    function setTokenURI(uint256 _tokenId, uint256 _uri) external onlyOwner {
        require(
            _exists(_tokenId),
            "ERC721Metadata: URI set of nonexistent token"
        );
        _tokenURIs[_tokenId] = _uri;
    }

    // Hide identity or show identity from here
    function setBaseURI(string memory _baseURI_) external onlyOwner {
        baseURI = _baseURI_;
    }

    function _beforeTokenTransfer(
        address _from,
        address _to,
        uint256 _tokenId
    ) internal virtual override(ERC721) {
        super._beforeTokenTransfer(_from, _to, _tokenId);
    }

    ///////////////////////////////////////
    // Query methods: Read Contract Part //
    ///////////////////////////////////////

    function exists(uint256 _tokenId) external view returns (bool) {
        return _exists(_tokenId);
    }

    function penguinsRemainingToBeMinted() public view returns (uint256) {
        return totalTokenToMint - purchasedPenguins;
    }

    function isAllTokenMinted() public view returns (bool) {
        return purchasedPenguins == totalTokenToMint;
    }

    function getIpfsIdToMint() private view returns (uint256 _nextIpfsId) {
        require(!isAllTokenMinted(), "All tokens have been minted");
        if (
            _lastIpfsId == totalTokenToMint &&
            purchasedPenguins < totalTokenToMint
        ) {
            _nextIpfsId = 1;
        } else if (purchasedPenguins < totalTokenToMint) {
            _nextIpfsId = _lastIpfsId + 1;
        }
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        return
            bytes(baseURI).length > 0
                ? string(
                    abi.encodePacked(baseURI, _tokenURIs[tokenId].toString())
                )
                : "";
    }

    function isApprovedOrOwner(address _spender, uint256 _tokenId)
        external
        view
        returns (bool)
    {
        return _isApprovedOrOwner(_spender, _tokenId);
    }

    //random number
    function random(
        uint256 from,
        uint256 to,
        uint256 salty
    ) private view returns (uint256) {
        uint256 seed = uint256(
            keccak256(
                abi.encodePacked(
                    block.timestamp +
                        block.difficulty +
                        ((
                            uint256(keccak256(abi.encodePacked(block.coinbase)))
                        ) / (block.timestamp)) +
                        block.gaslimit +
                        ((uint256(keccak256(abi.encodePacked(_msgSender())))) /
                            (block.timestamp)) +
                        block.number +
                        salty
                )
            )
        );
        return (seed % (to - from)) + from;
    }
}