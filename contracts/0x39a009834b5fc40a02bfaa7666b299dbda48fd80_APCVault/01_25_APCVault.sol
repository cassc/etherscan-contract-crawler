//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "./AngryPitbullClub.sol";
import "./AngryPitbullClubStaked.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./Bone.sol";

contract APCVault is Ownable, IERC721Receiver, ReentrancyGuard {
    // Custom errors
    error TokenIdNotStaked();
    error NotYourToken();
    error AlreadyEnabled();
    error AlreadyDisabled();

    // State variables

    uint256 public totalStaked;

    uint256 public score = 10000000000000000000;

    bool public emergencyActive;

    struct Stake {
        address owner;
        uint24 tokenId;
        bool isStaked;
        uint256 lastClaimed;
        bool claimAllEnabled;
    }

    // Events

    event APCStaked(address owner, uint256 tokenId);
    event APCUnstaked(address owner, uint256 tokenId);
    event Claimed(address owner, uint256 amount);

    // Contract instances and mappings

    AngryPitbullClubStaked public stakedAPC =
        AngryPitbullClubStaked(0x80Fbd25ac1bB7ADfccE0Cb92BE6AC32973Dd03c6);

    AngryPitbullClub public apc =
        AngryPitbullClub(0x05Fee3B8e939acBb4E8073D784e3EC0977509770);

    Bone public token = Bone(0x89fC60863F9aaA39166a4d378dccEf510e1D8306);

    mapping(uint256 => Stake) public vault;

    mapping(address => uint256) public claimAllAmount;

    mapping(address => uint256) public claimAllTimeStamp;

    mapping(address => bool) public controllers;

    constructor() {}

    function setBone(Bone _newToken) external onlyOwner {
        token = _newToken;
    }

    function setContract(AngryPitbullClub _newContract) external onlyOwner {
        apc = _newContract;
    }

    function setStakedAPCContract(
        AngryPitbullClubStaked _newContract
    ) external onlyOwner {
        stakedAPC = _newContract;
    }

    function stake(uint256[] calldata tokenIds, bool forClaimAll) external {
        uint256 tokenId;
        for (uint256 i = 0; i < tokenIds.length; i++) {
            tokenId = tokenIds[i];
            if (apc.ownerOf(tokenId) != msg.sender) revert NotYourToken();

            apc.transferFrom(msg.sender, address(this), tokenId);
            emit APCStaked(msg.sender, tokenId);

            vault[tokenId] = Stake({
                owner: msg.sender,
                tokenId: uint24(tokenId),
                isStaked: true,
                lastClaimed: block.timestamp,
                claimAllEnabled: forClaimAll
            });
        }
        if (forClaimAll) {
            claimAll();
            claimAllAmount[msg.sender] += tokenIds.length;
        }
        stakedAPC.batchMint(msg.sender, tokenIds);
        totalStaked += tokenIds.length;
    }

    function addController(address controller) external onlyOwner {
        controllers[controller] = true;
    }

    function removeController(address controller) external onlyOwner {
        controllers[controller] = false;
    }

    function claim(uint256[] calldata tokenIds) external nonReentrant {
        _claim(msg.sender, tokenIds, false);
    }

    function claimAll() public {
        if (claimAllTimeStamp[msg.sender] == 0) {
            claimAllTimeStamp[msg.sender] = block.timestamp;
        }
        if (claimAllAmount[msg.sender] == 0) {
            claimAllTimeStamp[msg.sender] = block.timestamp;
        }
        uint256 amount = claimAllAmount[msg.sender];
        uint256 localScore = score;
        uint256 earned = (amount *
            ((localScore * (block.timestamp - claimAllTimeStamp[msg.sender])) /
                1 days));

        claimAllTimeStamp[msg.sender] = block.timestamp;
        token.mint(msg.sender, earned);
    }

    function addToClaimAlls(uint256[] calldata tokenIds) external nonReentrant {
        uint256 tokenId;
        claimAll();
        _claim(msg.sender, tokenIds, false);
        for (uint256 i = 0; i < tokenIds.length; i++) {
            tokenId = tokenIds[i];
            if (vault[tokenId].claimAllEnabled) revert AlreadyEnabled();
            vault[tokenId].claimAllEnabled = true;
        }
        claimAllAmount[msg.sender] += tokenIds.length;
    }

    function isClaimAllEnabledForToken(
        uint256 tokenId
    ) external view returns (bool) {
        return vault[tokenId].claimAllEnabled;
    }

    function getClaimAllAmountForAddress(
        address addr
    ) external view returns (uint256) {
        return claimAllAmount[addr];
    }

    function getLastClaimedOfTokenId(
        uint256 tokenId
    ) external view returns (uint256) {
        return vault[tokenId].lastClaimed;
    }

    function removeFromClaimAll(uint256[] calldata tokenIds) public {
        uint256 tokenId;
        claimAll();

        for (uint256 i = 0; i < tokenIds.length; i++) {
            tokenId = tokenIds[i];
            if (!vault[tokenId].claimAllEnabled) revert AlreadyDisabled();
            vault[tokenId].claimAllEnabled = false;
            vault[tokenId].lastClaimed = block.timestamp;
        }
        claimAllAmount[msg.sender] -= tokenIds.length;
    }

    function removeClaim(uint256 tokenId) private {
        vault[tokenId].claimAllEnabled = false;
        vault[tokenId].lastClaimed = block.timestamp;
        claimAllAmount[msg.sender] -= 1;
    }

    function claimForAddress(
        address account,
        uint256[] calldata tokenIds
    ) external {
        require(controllers[msg.sender], "Only controllers can do this action");
        _claim(account, tokenIds, false);
    }

    function unstake(uint256[] calldata tokenIds) external nonReentrant {
        _claim(msg.sender, tokenIds, true);
    }

    function setBaseScore(uint256 _newScore) external onlyOwner {
        score = _newScore;
    }

    function _claim(
        address account,
        uint256[] calldata tokenIds,
        bool _unstake
    ) internal {
        uint256 localScore = score;
        uint256 tokenId;
        uint256 earned = 0;

        for (uint i = 0; i < tokenIds.length; i++) {
            tokenId = tokenIds[i];
            require(vault[tokenId].owner == account, "not an owner");

            if (vault[tokenId].claimAllEnabled) {
                earned +=
                    (localScore *
                        (block.timestamp - claimAllTimeStamp[msg.sender])) /
                    1 days;

                removeClaim(tokenId);
            }

            Stake memory staked = vault[tokenId];

            earned +=
                (localScore * (block.timestamp - staked.lastClaimed)) /
                1 days;

            vault[tokenId].lastClaimed = block.timestamp;
        }

        if (earned > 0) {
            token.mint(account, earned);
        }
        if (_unstake) {
            vault[tokenId].isStaked = !_unstake;
            _unstakeMany(account, tokenIds);
        }
        emit Claimed(account, earned);
    }

    function toggleEmergencyActive() external onlyOwner {
        emergencyActive = !emergencyActive;
    }

    function emergencyUnstake(uint256[] calldata tokenIds) external {
        require(emergencyActive, "Only in emergencies");
        _unstakeMany(msg.sender, tokenIds);
    }

    function _unstakeMany(
        address account,
        uint256[] calldata tokenIds
    ) internal {
        for (uint i = 0; i < tokenIds.length; i++) {
            if ((vault[tokenIds[i]].owner) != account) revert NotYourToken();

            delete vault[tokenIds[i]];
            emit APCUnstaked(account, tokenIds[i]);
            apc.transferFrom(address(this), account, tokenIds[i]);
        }
        stakedAPC.batchBurn(tokenIds);
        totalStaked -= tokenIds.length;
    }

    function emergencyPullOut(uint256[] calldata tokenIds) external onlyOwner {
        require(emergencyActive, "Only in emergencies");
        for (uint i = 0; i < tokenIds.length; i++) {

            apc.transferFrom(address(this), msg.sender, tokenIds[i]);
        }
    }

    function tokensOfOwner(
        address account
    ) public view returns (uint256[] memory ownerTokens) {
        uint256 supply = apc.totalSupply();
        uint256[] memory tmp = new uint256[](supply);

        uint256 index = 0;
        for (uint256 tokenId = 0; tokenId < supply; tokenId++) {
            if (vault[tokenId].owner == account) {
                tmp[index] = vault[tokenId].tokenId;
                index += 1;
            }
        }

        uint256[] memory tokens = new uint256[](index);
        for (uint256 i = 0; i < index; i++) {
            tokens[i] = tmp[i];
        }

        return tokens;
    }

    function getAllIdsThatAreClaimAllEnabled()
        public
        view
        returns (uint256[] memory)
    {
        uint256 supply = apc.totalSupply();
        uint256[] memory tmp = new uint256[](supply);

        uint256 index = 0;
        for (uint256 tokenId = 0; tokenId < supply; tokenId++) {
            if (vault[tokenId].claimAllEnabled) {
                tmp[index] = vault[tokenId].tokenId;
                index += 1;
            }
        }

        uint256[] memory tokens = new uint256[](index);
        for (uint256 i = 0; i < index; i++) {
            tokens[i] = tmp[i];
        }

        return tokens;
    }

    function getAllIdsThatAreClaimAllEnabledOfOwner(
        address account
    ) public view returns (uint256[] memory) {
        uint256 supply = apc.totalSupply();
        uint256[] memory tmp = new uint256[](supply);

        uint256 index = 0;
        for (uint256 tokenId = 0; tokenId < supply; tokenId++) {
            if (
                vault[tokenId].owner == account &&
                vault[tokenId].claimAllEnabled
            ) {
                tmp[index] = vault[tokenId].tokenId;
                index += 1;
            }
        }

        uint256[] memory tokens = new uint256[](index);
        for (uint256 i = 0; i < index; i++) {
            tokens[i] = tmp[i];
        }

        return tokens;
    }

    function tokensOfOwnerUnstaked(
        address account
    ) public view returns (uint256[] memory ownerTokens) {
        uint256 supply = apc.totalSupply();
        uint256[] memory tmp = new uint256[](apc.balanceOf(account));

        uint256 index = 0;
        for (uint256 tokenId = 0; tokenId < supply; tokenId++) {
            if (apc.ownerOf(tokenId) == account) {
                tmp[index] = tokenId;
                index += 1;
            }
        }

        uint256[] memory tokens = new uint256[](index);
        for (uint256 i = 0; i < index; i++) {
            tokens[i] = tmp[i];
        }

        return tokens;
    }

    function isTokenIdStaked(uint256 tokenId) external view returns (bool) {
        return vault[tokenId].isStaked;
    }

    function getOwnerOfStakedToken(
        uint256 tokenId
    ) external view returns (address) {
        if (!vault[tokenId].isStaked) revert TokenIdNotStaked();
        return vault[tokenId].owner;
    }

    function onERC721Received(
        address,
        address from,
        uint256,
        bytes calldata
    ) external pure override returns (bytes4) {
        require(from == address(0x0), "Cannot send nfts to Vault directly");
        return IERC721Receiver.onERC721Received.selector;
    }
}