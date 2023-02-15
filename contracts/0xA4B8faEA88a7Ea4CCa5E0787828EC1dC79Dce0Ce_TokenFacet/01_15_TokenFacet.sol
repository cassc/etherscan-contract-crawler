// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "../@openzeppelin/contracts/utils/Context.sol";
import "../@openzeppelin/contracts/utils/Base64.sol";
import "../@openzeppelin/contracts/utils/cryptography/SignatureChecker.sol";
import "../libraries/ERC721A.sol";
import "../libraries/AppStorage.sol";
import "../libraries/LibDiamond.sol";
import "../libraries/Constants.sol";

contract TokenFacet is
	ERC721A,
	Context
{

    // =================================
	// Events
	// =================================

    event Renew(
        uint256 tokenId,
        uint256 daysNum,
        uint256 newDeadline
        );

    event Minted(
        uint256 tokenId,
        address owner,
        uint256 deadline
        );
	
	// =================================
	// Minting
	// =================================

	function mint(uint8 _v, bytes32 _r, bytes32 _s)
		external
        payable
	{
		require(totalSupply() + 1 <= getState().maxSupply, "Out of mint limits");
        require(verifySignedAddress(_v, _r, _s), "Invalid signature");
        require(msg.value >= getState().mintPrice, "Not enough funds");

        getState().subscriptionDeadline[getState().currentIndex] = block.timestamp + (1 days * getState().afterMintSubscription);

        getState().mintNonce[_msgSender()] += 1;
		_safeMint(_msgSender(), 1);
        emit Minted(getState().currentIndex, _msgSender(), getState().subscriptionDeadline[getState().currentIndex]);
	}

    // =============================================================
    // View functions
    // =============================================================

    function getAfterMintSubscription() public view returns(uint256) {
        return (getState().afterMintSubscription);
    }

    function getPublicKey() public view returns(address) {
        return (getState().publicKey);
    }

    function getMaxSupply() public view returns(uint256) {
        return (getState().maxSupply);
    }

    function getSubscriptionDeadline(uint256 tokenId) public view returns(uint256) {
        return (getState().subscriptionDeadline[tokenId]);
    }

	function getRenewSubscriptionPrice() public view returns(uint256) {
        return (getState().renewSubscriptionPrice);
    }

    function getNonce(uint256 tokenId) public view returns(uint256) {
        return (getState().nonce[tokenId]);
    }

    function getMintNonce(address account) public view returns(uint256) {
        return (getState().mintNonce[account]);
    }

    function getCurrentIndex() public view returns(uint256) {
        return (getState().currentIndex);
    }

    function isTokenPaused(uint256 tokenId) public view returns(bool) {
        return (getState().pauseTransfer[tokenId]);
    }

    function isTransfersPaused() public view returns(bool) {
        return (getState().pauseAllTransfers);
    }

    function getMintPrice() public view returns(uint256) {
        return (getState().mintPrice);
    }

	// =============================================================
    // Renew functions
    // =============================================================

    function renewSubscription(uint256 tokenId) public payable {
        require(msg.value == getState().renewSubscriptionPrice, "Invalid msg.value");
        renewer(tokenId, 30);
    }

    function renewSubscriptionForSeveralMonth(uint256 tokenId, uint256 monthNum) public payable {
        require(msg.value == getState().renewSubscriptionPrice * monthNum, "Invalid msg.value");
        renewer(tokenId, monthNum * 30);
    }

    function freeRenewSubscription(uint256 tokenId, uint256 daysNum, uint8 _v, bytes32 _r, bytes32 _s) public {
        require(verifySignedAddressRenew(_v, _r, _s, tokenId, daysNum), "Invalid signature");
        getState().nonce[tokenId] = getState().nonce[tokenId] + 1;
        renewer(tokenId, daysNum);
    }

	// =============================================================
    // Admin setters
    // =============================================================

	function kickMember(uint256 tokenId) public onlyOwner {
        _burn(tokenId);
    }

    function takeAwaySubscription(uint256 tokenId, uint256 daysNum) public onlyOwner {
        getState().subscriptionDeadline[tokenId] = getState().subscriptionDeadline[tokenId] - (1 days * daysNum);
    }

	function setRenewSubscriptionPrice(uint256 _renewSubscriptionPrice) public onlyOwner {
        getState().renewSubscriptionPrice = _renewSubscriptionPrice;
    }

    function setAfterMintSubscription(uint256 daysNum) public onlyOwner {
        getState().afterMintSubscription = daysNum;
    }

	function setMaxSupply(uint256 _maxSupply) public onlyOwner {
        require(_maxSupply >= totalSupply(), "New max supply must be greater than current");
        getState().maxSupply = _maxSupply;
    }

    function setPublicKey(address _publicKey) public onlyOwner {
        getState().publicKey = _publicKey;
    }

    function setBaseURI(string memory uri) public onlyOwner {
        getState().baseURI = uri;
    }

    function setMintPrice(uint256 _mintPrice) public onlyOwner {
        getState().mintPrice = _mintPrice;
    }

    // =============================================================
    // Admin withdraw
    // =============================================================

    function withdrawEth() public onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    // =============================================================
    // Admin airDrop
    // =============================================================

    function airDropSubscriptionForToken(uint256 tokenId, uint256 daysNum) public onlyOwner {
        renewer(tokenId, daysNum);
    }

    function airDropSubscriptionForActiveTokens(uint256 daysNum) public onlyOwner {
        for (uint256 i = 0; i < totalSupply(); i++) {
            if (getState().subscriptionDeadline[i] > block.timestamp) {
                renewer(i, daysNum);
            }
        }
    }

    function airDropSubscriptionForAllTokens(uint256 daysNum) public onlyOwner {
        for (uint256 i = 0; i < totalSupply(); i++) {
            renewer(i, daysNum);
        }
    }

    // =============================================================
    // Admin pause
    // =============================================================

    function flipPauseAllTransfers() public onlyOwner {
        getState().pauseAllTransfers = !getState().pauseAllTransfers;
    }

    function flipPauseOneToken(uint256 NFTnum) public onlyOwner {
        getState().pauseTransfer[NFTnum] = !getState().pauseTransfer[NFTnum];
    }

    // =================================
	// Internal functions
	// =================================

    function renewer(uint256 tokenId, uint256 daysNum) internal {
        require(_exists(tokenId), "nonexistent token");

        if (getState().subscriptionDeadline[tokenId] < block.timestamp) {
            getState().subscriptionDeadline[tokenId] = block.timestamp + (1 days * daysNum);
        } else {
            getState().subscriptionDeadline[tokenId] = getState().subscriptionDeadline[tokenId] + (1 days * daysNum);
        }
        emit Renew(tokenId, daysNum, getState().subscriptionDeadline[tokenId]);
    }

    function verifySignedAddress(
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) internal view returns (bool) {
        bytes32 prefixedHashMessage = keccak256(abi.encodePacked(Constants.PREFIX, keccak256(abi.encodePacked(msg.sender, getState().mintNonce[_msgSender()]))));
        address signer = ecrecover(prefixedHashMessage, _v, _r, _s);
        return signer == getState().publicKey;
    }

    function verifySignedAddressRenew(
        uint8 _v,
        bytes32 _r,
        bytes32 _s,
        uint256 tokenId,
        uint256 daysNum
    ) internal view returns (bool) {
        bytes32 prefixedHashMessage = keccak256(abi.encodePacked(Constants.PREFIX, keccak256(abi.encodePacked(tokenId, daysNum, getState().nonce[tokenId]))));
        address signer = ecrecover(prefixedHashMessage, _v, _r, _s);
        return signer == getState().publicKey;
    }

	// =================================
	// Metadata
	// =================================

    function _baseURI() internal view virtual override returns (string memory) {
        return getState().baseURI;
    }

    function tokenURI(uint256 tokenId) override public view returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        bool isExpired = getState().subscriptionDeadline[tokenId] < block.timestamp;

        return string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Base64.encode(
                        bytes(
                            abi.encodePacked(
                                '{"attributes":[{"trait_type":"Expired","value":"', (isExpired) ? "true" : "false", '"},{"trait_type":"Expiry Timestamp","value":"', (isExpired) ? "Already expired" : uint2str((getState().subscriptionDeadline[tokenId] - block.timestamp) / (60 * 60 * 24)), '"}],',
                                '"description":"Exclusive community of the most ambitious Developers, Builders, NFT Investors and Artists in the Web3 space. Holders get access to up-to-date alpha information about all ongoing NFT-sales, investments, raffles and more.",',
                                '"image":"', (isExpired) ? (string(bytes.concat(bytes(getState().baseURI), bytes("expired.MP4")))) : (string(bytes.concat(bytes(getState().baseURI), bytes("activated.MP4")))), '",',
                                '"name":"', (isExpired) ? "Minus Pass" : "Plus Pass" ,' | ', uint2str(tokenId + 1),'",',
                                '"tokenId":"', uint2str(tokenId + 1), '"}'
                            )
                        )
                        
                    )
                )
            );
    }

    function uint2str(uint _i) internal pure returns (string memory _uintAsString) {
        if (_i == 0) {
            return "0";
        }
        uint j = _i;
        uint len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len;
        while (_i != 0) {
            k = k-1;
            uint8 temp = (48 + uint8(_i - _i / 10 * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
    }

    // =================================
	// Funcition overriding
	// =================================

    function _beforeTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal override {

        if (from != address(0) && to != address(0)) {
            require(!getState().pauseTransfer[startTokenId], "transfer is paused for you");
            require(!getState().pauseAllTransfers, "transfer is paused");
        }

    }   

	// =================================
	// Constructor
	// =================================

	constructor() ERC721A(Constants.NAME, Constants.SYMBOL) {}

}