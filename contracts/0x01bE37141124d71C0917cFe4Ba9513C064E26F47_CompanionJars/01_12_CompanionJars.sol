// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;


import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

abstract contract PixieDust {
    function mintDust(address to, uint256 amount) external virtual;
}

contract CompanionJars is ERC721, Ownable, IERC721Receiver {
    using Strings for uint256;
    using Strings for uint32;

    struct CompanionData {
        address companionCollection;
        uint32 companionTokenId;
    }

    struct StakeData {
        uint64 lastBlock;
        uint64 lastTotal;
    }

    PixieDust pixieDust;
    IERC721 pixieJars;

    string _baseTokenURI;
    string internal _contractURI = "";
    string constant URI_SEPARATOR = "/";
    uint256 public PIXIE_DUST_PER_STAKE_PER_BLOCK = (10**18 - 6400) / 7200;
    mapping(uint256 => CompanionData) public companionInfo;
    mapping(uint256 => address) public stakedBy;
    mapping(address => StakeData) public stakingInfo;
    mapping(address => bool) public allowedCompanions;

    constructor(string memory mContractURI, string memory baseURI, address _pixieJars, address _pixieDust) ERC721("Companion Jars", "CJ") {
        _baseTokenURI = baseURI;
        _contractURI = mContractURI;
        pixieJars = IERC721(_pixieJars);
        pixieDust = PixieDust(_pixieDust);
    }

    function setDustContract(address _dust) external onlyOwner {
        pixieDust = PixieDust(_dust);
    }

    function setPixieJarsContract(address _address) external onlyOwner {
        pixieJars = IERC721(_address);
    }

    function setContractURI(string calldata newContractURI) external onlyOwner {
        _contractURI = newContractURI;
    }

    function setAllowedCompanion(address _address, bool _allowed) external onlyOwner {
        allowedCompanions[_address] = _allowed;
    }

    function setPixieDustPerBlock(uint256 _pdpb) external onlyOwner {
        PIXIE_DUST_PER_STAKE_PER_BLOCK = _pdpb;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        _requireMinted(tokenId);

        string memory baseURI = _baseTokenURI;
        CompanionData memory companion = companionInfo[tokenId];
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString(), URI_SEPARATOR, Strings.toHexString(uint256(uint160(companion.companionCollection))), URI_SEPARATOR, companion.companionTokenId.toString())) : "";
    }

    function contractURI() external view returns (string memory) {
        return _contractURI;
    }

    function stakePixie(uint256[] calldata pixieTokenId, address[] calldata companionAddress, uint256[] calldata companionTokenId) external {
        require(pixieTokenId.length == companionAddress.length && companionAddress.length == companionTokenId.length, "INVALID ARRAY LENGTHS");
        IERC721 companionContract;
        CompanionData memory newCompanion;
        for(uint256 i = 0;i < pixieTokenId.length;i++) {
            require(allowedCompanions[companionAddress[i]], "INVALID COMPANION");
            newCompanion.companionCollection = companionAddress[i];
            newCompanion.companionTokenId = uint32(companionTokenId[i]);
            stakedBy[pixieTokenId[i]] = msg.sender;
            companionInfo[pixieTokenId[i]] = newCompanion;
            companionContract = IERC721(companionAddress[i]);
            pixieJars.safeTransferFrom(msg.sender, address(this), pixieTokenId[i]);
            companionContract.safeTransferFrom(msg.sender, address(this), companionTokenId[i]);
            _mint(msg.sender, pixieTokenId[i]);
        }
    }

    function swapCompanion(uint256[] calldata pixieTokenId, address[] calldata companionAddress, uint256[] calldata companionTokenId) external {
        require(pixieTokenId.length == companionAddress.length && companionAddress.length == companionTokenId.length, "INVALID ARRAY LENGTHS");
        IERC721 companionContract;
        CompanionData memory companion;
        for(uint256 i = 0;i < pixieTokenId.length;i++) {
            require(stakedBy[pixieTokenId[i]] == msg.sender, "ONLY STAKER CAN SWAP COMPANION");
            require(allowedCompanions[companionAddress[i]], "INVALID COMPANION");

            companion = companionInfo[pixieTokenId[i]];
            companionContract = IERC721(companion.companionCollection);
            companionContract.safeTransferFrom(address(this), msg.sender, companion.companionTokenId);
            
            companion.companionCollection = companionAddress[i];
            companion.companionTokenId = uint32(companionTokenId[i]);
            companionInfo[pixieTokenId[i]] = companion;
            companionContract = IERC721(companionAddress[i]);
            companionContract.safeTransferFrom(msg.sender, address(this), companionTokenId[i]);
        }
    }

    function unstakePixie(uint256[] calldata pixieTokenId) external {
        CompanionData memory companion;
        IERC721 companionContract;
        for(uint256 i = 0;i < pixieTokenId.length;i++) {
            require(stakedBy[pixieTokenId[i]] == msg.sender, "ONLY STAKER CAN UNSTAKE");

            companion = companionInfo[pixieTokenId[i]];
            companionContract = IERC721(companion.companionCollection);
            companionContract.safeTransferFrom(address(this), msg.sender, companion.companionTokenId);
            pixieJars.safeTransferFrom(address(this), msg.sender, pixieTokenId[i]);

            delete companionInfo[pixieTokenId[i]];
            delete stakedBy[pixieTokenId[i]];
            _burn(pixieTokenId[i]);
        }
    }

    function claimDust() external {
        StakeData memory stakeData = stakingInfo[msg.sender];
        uint256 tokenBalance = balanceOf(msg.sender);
        uint256 dustEarned = (stakeData.lastTotal + (block.number - stakeData.lastBlock) * tokenBalance) * PIXIE_DUST_PER_STAKE_PER_BLOCK;
        require(dustEarned > 0);
        stakeData.lastTotal = uint64(0);
        stakeData.lastBlock = uint64(block.number);
        stakingInfo[msg.sender] = stakeData;
        pixieDust.mintDust(msg.sender, dustEarned);
    }

    function unclaimedDust(address staker) external view returns(uint256) {
        StakeData memory stakeData = stakingInfo[staker];
        uint256 tokenBalance = balanceOf(staker);
        uint256 dustEarned = (stakeData.lastTotal + (block.number - stakeData.lastBlock) * tokenBalance) * PIXIE_DUST_PER_STAKE_PER_BLOCK;
        return dustEarned;
    }

    function _afterTokenTransfer(address from, address to, uint256, uint256) internal override {
        address staker;
        uint256 tokenBalance = 0;
        if(from == address(0)) {
            staker = to;
            tokenBalance = balanceOf(staker) - 1;
        } else if(to == address(0)) {
            staker = from;
            tokenBalance = balanceOf(staker) + 1;
        } else {
            revert("WALLET TO WALLET TRANSFER NOT ALLOWED.");
        }
        StakeData memory stakeData = stakingInfo[staker];
        stakeData.lastTotal = stakeData.lastTotal + uint64((block.number - stakeData.lastBlock) * tokenBalance);
        stakeData.lastBlock = uint64(block.number);
        stakingInfo[staker] = stakeData;
    }

    function setApprovalForAll(address, bool) public virtual override {
        revert("Cannot set approval for all on staked tokens.");
    }

    function approve(address, uint256) public virtual override {
        revert("Cannot set approval on staked token.");
    }

    function onERC721Received(address _operator, address, uint, bytes memory) public virtual override returns (bytes4) {
        if (_operator != address(this)) return bytes4(0);
        return IERC721Receiver.onERC721Received.selector;
    }
}