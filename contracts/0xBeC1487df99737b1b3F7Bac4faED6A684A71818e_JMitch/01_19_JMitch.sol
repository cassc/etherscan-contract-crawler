// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

// import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
// import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import '@openzeppelin/contracts/token/ERC721/extensions/ERC721Royalty.sol';
import '@openzeppelin/contracts/access/AccessControl.sol';

contract JMitch is ERC721Enumerable, ERC721Royalty, Ownable, ReentrancyGuard, AccessControl {
    using Strings for uint256;

    //can only be lowered
    uint256 public totalTokensToMint = 10000;

    //toggle the minting
    bool public isMintingActive = true;

    //toggle instant reveal
    bool public instantRevealActive = false;

    //the enumerable part from ERC721Enumerable
    uint256 public tokenIndex = 0;

    uint256 public pricePerNFT = 19874000000000000; // 0.019874 ETH

    string private _baseTokenURI =
        "https://coral-cheap-gecko-166.mypinata.cloud/ipfs/QmfRVEzfe88aHLp3nwGR4G9XyDtF7dpuWQQ4ZHMzkra5bG/";         //base Token URI

    //triggers on gamification event
    event CustomThing(
        uint256 nftID,
        uint256 value,
        uint256 actionID,
        string payload
    );

    constructor() ERC721("JMitch", "JMitch") {}

    /* @dev
     * buy max 20 tokens
     */
    function buy(address recipient, uint256 amount) public payable nonReentrant {
        require(amount <= 50, "max 50 tokens");
        require(amount > 0, "minimum 1 token");
        require(
            amount <= totalTokensToMint - tokenIndex,
            "greater than max supply"
        );
        require(isMintingActive, "minting is not active");
        require(pricePerNFT * amount == msg.value, "exact value in ETH needed");
        for (uint256 i = 0; i < amount; i++) {
            _mintToken(recipient);
        }
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(AccessControl, ERC721Enumerable, ERC721Royalty)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }


    /**
     * @dev See {ERC721-_burn}.
     */
    function _burn(uint256 tokenId) internal override(ERC721, ERC721Royalty) {
        super._burn(tokenId);
    }

    /**
     * @dev See {ERC721Enumerable-_beforeTokenTransfer}.
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }


    /* @dev
     * In case tokens are not sold, admin can mint them for giveaways, airdrops etc
     */
    function adminMint(uint256 amount) public onlyOwner {
        require(
            amount <= totalTokensToMint - tokenIndex,
            "amount is greater than the token available"
        );
        for (uint256 i = 0; i < amount; i++) {
            _mintToken(_msgSender());
        }
    }

    /* @dev
     * Internal mint function
     */
    function _mintToken(address destinationAddress) private {
        tokenIndex++;
        require(!_exists(tokenIndex), "Token already exist.");
        _safeMint(destinationAddress, tokenIndex);
    }

    /* @dev
     * Custom thing
     */
    function customThing(
        uint256 nftID,
        uint256 id,
        string memory what
    ) external payable {
        require(ownerOf(nftID) == msg.sender, "NFT ownership required");
        emit CustomThing(nftID, msg.value, id, what);
    }

    /* @dev
     * Helper function, get the tokens of an address without using crazy things
     */
    function tokensOfOwner(
        address _owner,
        uint256 _start,
        uint256 _limit
    ) external view returns (uint256[] memory) {
        uint256 tokenCount = balanceOf(_owner);
        if (tokenCount == 0) {
            return new uint256[](0);
        } else {
            uint256[] memory result = new uint256[](tokenCount);
            uint256 index;
            for (index = _start; index < _limit; index++) {
                result[index] = tokenOfOwnerByIndex(_owner, index);
            }
            return result;
        }
    }

    /* @dev
     * Burn...
     */
    function burn(uint256 tokenId) public virtual {
        require(
            _isApprovedOrOwner(_msgSender(), tokenId),
            "caller is not owner nor approved"
        );
        _burn(tokenId);
    }

    function exists(uint256 _tokenId) external view returns (bool) {
        return _exists(_tokenId);
    }

    function isApprovedOrOwner(address _spender, uint256 _tokenId)
        external
        view
        returns (bool)
    {
        return _isApprovedOrOwner(_spender, _tokenId);
    }


    /*
     * @dev
     *  ██████  ██     ██ ███    ██ ███████ ██████      ███████ ██    ██ ███    ██  ██████ ████████ ██  ██████  ███    ██ ███████
     * ██    ██ ██     ██ ████   ██ ██      ██   ██     ██      ██    ██ ████   ██ ██         ██    ██ ██    ██ ████   ██ ██
     * ██    ██ ██  █  ██ ██ ██  ██ █████   ██████      █████   ██    ██ ██ ██  ██ ██         ██    ██ ██    ██ ██ ██  ██ ███████
     * ██    ██ ██ ███ ██ ██  ██ ██ ██      ██   ██     ██      ██    ██ ██  ██ ██ ██         ██    ██ ██    ██ ██  ██ ██      ██
     *  ██████   ███ ███  ██   ████ ███████ ██   ██     ██       ██████  ██   ████  ██████    ██    ██  ██████  ██   ████ ███████
     *
     */

    //@dev toggle instant Reveal
    function stopInstantReveal() external onlyOwner {
        instantRevealActive = false;
    }

    function startInstantReveal() external onlyOwner {
        instantRevealActive = true;
    }

    //toggle minting
    function stopMinting() external onlyOwner {
        isMintingActive = false;
    }

    //toggle minting
    function startMinting() external onlyOwner {
        isMintingActive = true;
    }

    function tokenURI(uint256 _tokenId)
        public
        view
        override
        returns (string memory)
    {
        require(
            _exists(_tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );
        return string(abi.encodePacked(_baseTokenURI, _tokenId.toString(),".json"));
    }

    function setBaseURI(string memory newBaseURI) public onlyOwner {
        _baseTokenURI = newBaseURI;
    }

    //used by admin to lower the total supply [only owner]
    function lowerTotalSupply(uint256 _newTotalSupply) public onlyOwner {
        require(_newTotalSupply < totalTokensToMint, "you can only lower it");
        totalTokensToMint = _newTotalSupply;
    }


    ////////////////
    // royalty
    ////////////////
    /**
     * @dev See {ERC2981-_setDefaultRoyalty}.
     */
    function setDefaultRoyalty(address receiver, uint96 feeNumerator) external onlyOwner {
        _setDefaultRoyalty(receiver, feeNumerator);
    }

    /**
     * @dev See {ERC2981-_deleteDefaultRoyalty}.
     */
    function deleteDefaultRoyalty() external onlyOwner {
        _deleteDefaultRoyalty();
    }

    /**
     * @dev See {ERC2981-_setTokenRoyalty}.
     */
    function setTokenRoyalty(
        uint256 tokenId,
        address receiver,
        uint96 feeNumerator
    ) external onlyOwner {
        _setTokenRoyalty(tokenId, receiver, feeNumerator);
    }

    /**
     * @dev See {ERC2981-_resetTokenRoyalty}.
     */
    function resetTokenRoyalty(uint256 tokenId) external onlyOwner {
        _resetTokenRoyalty(tokenId);
    }



    // [only owner]
    function withdrawEarnings() public onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    function uint2str(uint256 _i)
        internal
        pure
        returns (string memory _uintAsString)
    {
        if (_i == 0) {
            return "0";
        }
        uint256 j = _i;
        uint256 len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint256 k = len;
        while (_i != 0) {
            k = k - 1;
            uint8 temp = (48 + uint8(_i - (_i / 10) * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
    }
}