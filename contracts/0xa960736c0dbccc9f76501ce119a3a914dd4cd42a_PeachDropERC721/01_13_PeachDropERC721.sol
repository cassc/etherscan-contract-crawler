// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract PeachDropERC721 is ERC721, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;

    // Timestamp for activating redemption
    uint256 public activationTimestamp = 1690873200;

    // Timestamp for deactivating sale and redemption
    uint256 public deactivationTimestamp = 1694070000;

    // Address of payment safe
    address public beneficiary = 0xE9c47D17233E6aFD3d9020E0F8e2a86C2718dcfE;

    // Max supply of total tokens
    uint256 public maxSupply = 1000;

    // Mint price of each token (0.088 ETH)
    uint256 public mintPrice = 88000000000000000;

    // URI for the contract metadata
    string private _contractURI = "ipfs://Qmf2uCH5DCnMDB64z5rRW7idgfZSY25T5bmNEukir1zC6g";

    // baseURI_ String to prepend to unredeemed token IDs
    string private _baseURIUnredeemed = "ipfs://QmZcHzytDyfzZe2wxR2PHoaJVZELWuergGFwXiPTrFncj7";

    // baseURI_ String to prepend to redeemed token IDs. Revealed after redeem window is open.
    string private _baseURIRedeemed = "";

    // Indicates if Metadata uri is frozen
    bool public metdataFrozen = false;

    // Mapping of tokenID to bool
    mapping(uint256 => bool) public redeems;

    /**
     * @dev Initializes contract
     */
    constructor() ERC721("Peaches", "PEACH") {}

    /**
     * @dev Mints token to sender
     * Requirements:
     *
     * - `msg.value` must be exact payment amount in wei
     * - `nextTokenID must be less than the `maxSupply`
     * - `deactivationTimestamp` must be greater than the current block time
     */
    function harvest() public payable {
        require(mintPrice == msg.value, "Incorrect payment amount");
        require(deactivationTimestamp > block.timestamp, "Minting has ended");

        uint256 tokenId = _tokenIdCounter.current();
        require(tokenId < maxSupply, "No more tokens available to mint");

        payable(beneficiary).transfer(msg.value);

        _safeMint(msg.sender, tokenId + 1);
        _tokenIdCounter.increment();
    }

    /**
     * @dev Mints 1 nft to multiple addresses. For minting some tokens to our peach farmers.
     * @param _addresses List of addresses to mint to
     * Requirements:
     *
     * - `owner` must be function caller
     */
    function harvestTo(address[] memory _addresses) public onlyOwner {
        require(deactivationTimestamp > block.timestamp, "Minting has ended");
        for (uint i = 0; i < _addresses.length; i++) {
            uint256 tokenId = _tokenIdCounter.current();
            require(tokenId < maxSupply, "No more tokens available to mint");

            _safeMint(_addresses[i], tokenId + 1);
            _tokenIdCounter.increment();
        }
    }

    /**
     * @dev Marks tokenID as redeemed
     * @param _tokenId Timestamp to determine start of sale
     *
     * Requirements:
     * - `tokenId` holder must be function caller
     * - `tokenId` must exist
     * - 'tokenId` must not already be redeemed
     *  - minting/redemption window must still be open
     */
    function redeem(uint256 _tokenId) public {
        require(activationTimestamp <= block.timestamp, "Redemption has not started");
        require(deactivationTimestamp > block.timestamp, "Redemption has ended");
        require(_exists(_tokenId), "ERC721Metadata: URI query for nonexistent token");
        require(!redeems[_tokenId], "Token is already redeemed");

        address tokenOwner = ownerOf(_tokenId);
        require(tokenOwner == msg.sender, "msg.sender is not the owner of the token");

        redeems[_tokenId] = true;
    }

    /**
     * @dev Marks tokenIDs as redeemed
     * @param _tokenIds Array of tokenIds to mark redeemed
     *
     * Requirements:
     * - `owner` must be function caller
     * - `tokenId` must exist
     * - 'tokenId` must not already be redeemed
     *  - minting/redemption window must still be open
     */
    function batchRedeem(uint256[] memory _tokenIds) public onlyOwner {
        require(deactivationTimestamp > block.timestamp, "Redemption has ended");

        for (uint i = 0; i < _tokenIds.length; i++) {
            if (_exists(_tokenIds[i])) {
                redeems[_tokenIds[i]] = true;
            }
        }
    }

    /**
     * @dev Sets the price
     * @param _newPrice Price for overiding original price
     *
     * Requirements:
     * - `owner` must be function caller
     */
    function setPrice(uint256 _newPrice) public onlyOwner {
        mintPrice = _newPrice;
    }

    /**
     * @dev Sets the activationTimestap in case peaches are ready early
     * @param _newActivationTimestamp activationTimestap for overiding original activationTimestap
     *
     * Requirements:
     * - `owner` must be function caller
     */
    function setActivationTimestamp(uint256 _newActivationTimestamp) public onlyOwner {
        activationTimestamp = _newActivationTimestamp;
    }

    /**
     * @dev Sets the deactivationTimestap in case peach availability runs late
     * @param _newDeactivationTimestamp deactivationTimestap for overiding original deactivationTimestap
     *
     * Requirements:
     * - `owner` must be function caller
     */
    function setDeactivationTimestamp(uint256 _newDeactivationTimestamp) public onlyOwner {
        deactivationTimestamp = _newDeactivationTimestamp;
    }

    /**
     * @dev Sets the baseURIS
     * @param _newBaseURI Metadata URI used for overriding initialBaseURI
     * @param _newBaseURIRedeemed Metadata URI used for overriding initialBaseURIRedeemed
     * @param _isRedeemSetter Indicates if is the final URI setting for redeemed tokenIds. Will freeze metadata.
     *
     * Requirements:
     *
     * - `owner` must be function caller
     */
    function setBaseURIS(
        string memory _newBaseURI,
        string memory _newBaseURIRedeemed,
        bool _isRedeemSetter
    ) public onlyOwner {
        _baseURIUnredeemed = _newBaseURI;
        _baseURIRedeemed = _newBaseURIRedeemed;
        if (_isRedeemSetter) {
            setMetadataFrozen();
        }
    }

    /**
     * @dev Sets the metdataFrozen to true
     */
    function setMetadataFrozen() private {
        metdataFrozen = true;
    }

    /**
     * @dev Sets the contractURI
     * @param _newContractURI Metadata URI used for overriding contract URI
     *
     *
     * Requirements:
     *
     * - `owner` must be function caller
     */
    function setContractURI(string memory _newContractURI) public onlyOwner {
        _contractURI = _newContractURI;
    }

    /**
     * @dev Returns the tokenURI for a given tokenID
     * @param _tokenId tokenId
     * Requirements:
     *
     * - `tokenId` must exist
     */
    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        require(_exists(_tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURIForToken = _baseURIUnredeemed;
        if (redeems[_tokenId]) {
            baseURIForToken = _baseURIRedeemed;
        }
        return
            bytes(baseURIForToken).length > 0
                ? string(abi.encodePacked(baseURIForToken, "/", Strings.toString(_tokenId), ".json"))
                : "";
    }

    /**
     * @dev Returns the contract uri metadata
     */
    function contractURI() external view returns (string memory) {
        return _contractURI;
    }

    /**
     * @dev Returns the current tokenID
     */
    function totalSupply() external view returns (uint256) {
        return _tokenIdCounter.current();
    }
}