//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.4;
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

// add contract comments ie Netsec

contract Airdrop is Ownable, ReentrancyGuard, ERC721Enumerable {
    string public baseURI;
    using Counters for Counters.Counter;
    using Strings for uint256;
    Counters.Counter private _tokenIdCounter;
    bool public isSalePaused = false;
    uint256 public redeemCost;
    uint256 public redeemTime;
    address public depositAddress;
    uint256 public constant MAX_SUPPLY = 100;

    mapping(uint256 => address) public redeemed;

    /**
     * @dev Emitted when `contract owner` updates the base URI.
     */
    event BaseURI(string uri);

    /**
     * @dev Emitted when `contract owner` updates the redeem cost/token .
     */
    event RedeeemCost(uint256 indexed redeemAmount);

    /**
     * @dev Emitted when `contract owner` updates the ETH deposit Address .
     */
    event DepositAddress(address indexed depositAddress);

    /**
     * @dev Emitted when `tokenOwner` redeemed the particular token with given tokenId.
     */
    event TokenRedeem(uint256 indexed tokenId, bytes32 ringInfo, address indexed tokenHolder, address depositAddresss);

    /**
     * @dev Emitted when `tokenOwner` updates the redeemTime (Unix timestamps in seconds).
     */
    event TokenRedeeemTime(uint256 indexed tokenRedeemTime);

    constructor(
        string memory _uri,
        uint256 _weiAmount,
        uint256 _redeemTime
    ) ERC721("Lost Space Crew", "LSC:721") {
        baseURI = _uri;
        depositAddress = owner();
        redeemCost = _weiAmount;
        redeemTime = _redeemTime;
    }

    function adminMint() external onlyOwner {
        _tokenIdCounter.increment();
        uint256 tokenId = _tokenIdCounter.current();
        require(tokenId <= MAX_SUPPLY, "Total supply reached");
        _safeMint(msg.sender, tokenId);
    }

    // Perform minting to mltiple address as per provided sequence.
    function multiMint(address[] calldata _addressList) external onlyOwner nonReentrant {
        require(_addressList.length > 0, "Invalid address-list");
        require((totalSupply() + _addressList.length) <= MAX_SUPPLY, "Max Supply Reached");
        for (uint256 i = 0; i < _addressList.length; i = uncheckInc(i)) {
            if (_addressList[i] != address(0)) {
                _tokenIdCounter.increment();
                uint256 tokenId = _tokenIdCounter.current();
                _safeMint(_addressList[i], tokenId);
            }
        }
    }

    function redeemToken(uint256 _tokenId, bytes32 _ringInfo) external payable nonReentrant {
        require(!isSalePaused, "Sale paused");
        require(redeemTime >= block.timestamp, "RedeemTime already passed");
        require(redeemed[_tokenId] == address(0), "Token already redeemed");
        require(ownerOf(_tokenId) == msg.sender, "Non Owner");
        require(msg.value == redeemCost, "Invalid amount");
        redeemed[_tokenId] = msg.sender;
        emit TokenRedeem(_tokenId, _ringInfo, msg.sender, depositAddress);
        (bool sent, ) = payable(depositAddress).call{ value: msg.value }("");
        require(sent, "Failed to send Ether");
    }

    function updateBaseURI(string memory _uri) external onlyOwner {
        baseURI = _uri;
        emit BaseURI(_uri);
    }

    function updateDepositAddress(address _depositAddress) external onlyOwner {
        require(_depositAddress != address(0) && _depositAddress != depositAddress, "Invalid Deposit Address");
        depositAddress = _depositAddress;
        emit DepositAddress(depositAddress);
    }

    function updateredeemCost(uint256 _updatedRedeemCost) external onlyOwner {
        require(_updatedRedeemCost != 0 && _updatedRedeemCost != redeemCost, "Invalid Redeem Cost");
        redeemCost = _updatedRedeemCost;
        emit RedeeemCost(_updatedRedeemCost);
    }

    function updateRedeemTime(uint256 _redeemTime) external onlyOwner {
        require(_redeemTime > block.timestamp, "Invalid Redeem Time ");
        redeemTime = _redeemTime;
        emit TokenRedeeemTime(redeemTime);
    }

    function setSaleState(bool _saleStatus) external onlyOwner {
        require(_saleStatus != isSalePaused, "Invalid input");
        isSalePaused = _saleStatus;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function tokenURI(uint256 tokenId) public view override(ERC721) returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString(), ".json")) : "";
    }

    function getUnredeemedTokens(address _user) external view returns (uint256[] memory) {
        uint256 numTokens = balanceOf(_user);
        uint256[] memory tokenIds = new uint256[](numTokens);
        for (uint256 i = 0; i < numTokens; i++) {
            uint256 tok = tokenOfOwnerByIndex(_user, i);
            if (redeemed[tok] == address(0)) {
                tokenIds[i] = tok;
            } else {
                tokenIds[i] = 0;
            }
        }
        return (tokenIds);
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function uncheckInc(uint256 x) private pure returns (uint256) {
        unchecked {
            return x + 1;
        }
    }
}