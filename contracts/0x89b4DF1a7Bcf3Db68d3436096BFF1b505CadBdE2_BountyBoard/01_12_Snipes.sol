// SPDX-License-Identifier: Unlicensed

// Only Official OnChain Royale Contract Address: 0x0d3ad0deA3E13A2d9F23D557f953F074578BD565
// Bounty Board Contract Address May Vary

pragma solidity ^0.8.15;

import "erc721a/contracts/ERC721A.sol";
import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

interface ERC721TokenReceiver {
    function onERC721Received(
        address operator,
        address from,
        uint256 id,
        bytes calldata data
    ) external returns (bytes4);
}

contract OwnableDelegateProxy {}

contract ProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}

contract OnChainRoyale is Ownable, ERC721A {

    using ECDSA for bytes32;

    enum RoyaleStage {
        SIGNUPS,
        PREPARING,
        PLAYING
    }

    uint256 public PREPARATION_PERIOD_BLOCK_COUNT = 6000 * 3;

    uint256 public maxSupply = 8008;
    uint256 public MAX_PER_WALLET = 3;

    uint256 public startBlock;

    bool private bountyBoardSet;
    bool private requireSignature = true;

    string public baseURI = "https://onchainroyale.xyz/api/token/";
    string public contractURI = "https://onchainroyale.xyz/api/contractURI";

    address public bountyBoard;
    address private openSeaRegistryAddress = 0xa5409ec958C83C3f309868babACA7c86DCB077c1;
    address private _signer;


    constructor()
    ERC721A("OnChain Royale", "OCRNFT")
    {
        _mint(address(this), 1, "0x0", false);
        _burn(0);
        _signer = msg.sender;
    }


    function currentStage() public view returns (RoyaleStage) {
        if (_totalMinted() < maxSupply) {
            return RoyaleStage.SIGNUPS;
        }
        if ((startBlock + PREPARATION_PERIOD_BLOCK_COUNT) >= block.number) {
            return RoyaleStage.PREPARING;
        }
        return RoyaleStage.PLAYING;
    }

    function mint(
        uint256 amount,
        bytes memory signature
    ) external
    {
        require((_numberMinted(msg.sender) + amount) <= MAX_PER_WALLET, "OCRNFT_TOO_MANY_REQUESTED");
        require(msg.sender == tx.origin, "OCRNFT_ONLY_WALLETS");
        require(_totalMinted() + 1 <= maxSupply, "OCRNFT_SOLD_OUT");
        require(isValidProof(msg.sender, signature), "OCRNFT_FAILED_SIGNATURE");
        _mint(msg.sender, amount, "0x0", false);
        if (_totalMinted() == maxSupply) {
            startBlock = block.number;
        }
    }

    function kill(
        uint256 _targetId
    ) public
    {
        require(bountyBoard == msg.sender, "OCRNFT_ONLY_BOUNTY_BOARD");
        require(currentStage() == RoyaleStage.PLAYING, "OCRNFT_GAME_HAS_NOT_STARTED");
        _burn(_targetId);
    }

    function setContractURI(
        string memory _uri
    ) external onlyOwner
    {
        contractURI = _uri;
    }

    function setBaseURI(
        string memory _uri
    ) external onlyOwner
    {
        baseURI = _uri;
    }

    function isApprovedForAll(address owner, address operator) public override view returns (bool) {

        ProxyRegistry openSeaRegistry = ProxyRegistry(openSeaRegistryAddress);

        if (address(openSeaRegistry.proxies(owner)) == operator) {
            return true;
        }

        if (bountyBoardSet && bountyBoard == operator) {
            return true;
        }

        return super.isApprovedForAll(owner, operator);
    }

    function setRequireSignature(bool _require) external onlyOwner {
        requireSignature = _require;
    }

    function setOpenSeaRegistry(address _openSeaRegistry) external onlyOwner {
        openSeaRegistryAddress = _openSeaRegistry;
    }
    
    function registerBountyBoard(address _bountyBoard) external onlyOwner {
        bountyBoard = _bountyBoard;
        bountyBoardSet = true;
    }

    function deregisterBountyBoard(address _bountyBoard) external onlyOwner {
        bountyBoard = _bountyBoard;
        bountyBoardSet = false;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function isValidProof(address a, bytes memory proof) internal view returns (bool) {
        bytes32 data = keccak256(abi.encodePacked(a));
        return _signer == data.toEthSignedMessageHash().recover(proof);
    }
}

contract BountyBoard is Ownable, ERC721TokenReceiver {

    using ECDSA for bytes;
    
    struct StakingVault {
        uint256[] tokens;
        uint256 startBlock;
        uint256 balance;
        bool isStaked;
    }

    uint256 public STAKING_TIMELIMIT = 6000 * 7;
    uint256 public EMISSION_RATE = 63;
    uint256 public EMISSION_BLOCK_COUNT = 265;
    uint256 public KILL_PRICE = 1500;
    uint256 public BRIBE_PRICE = 0.01 * 1 ether;

    address public onChainRoyale;

    mapping(address => StakingVault) public stakingVaults;

    event BribePriceIncrease(uint256 price, address initiator);
    event PlayerKilled(uint256 tokenId, address killer);

    constructor(
        address _onChainRoyale
    ) {
        onChainRoyale = _onChainRoyale;
    }

    function editEmissionBlockCount(uint256 _blockCount) onlyOwner external {
        EMISSION_BLOCK_COUNT = _blockCount;
    }

    function editEmissionRate(uint256 _rate) onlyOwner external {
        EMISSION_RATE = _rate;
    }

    function killPlayer(
        uint256 _targetId
    ) external
    {
        OnChainRoyale ocr = OnChainRoyale(address(onChainRoyale));
        StakingVault memory killerVault = stakingVaults[msg.sender];

        require(ocr.balanceOf(msg.sender) > 0, "OCRBB_MUST_HAVE_ONE_FREE_PLAYER");
        require(killerVault.balance > KILL_PRICE, "OCRBB_INSUFFICIENT_BALANCE");

        address targetUser = ocr.ownerOf(_targetId);
        require(targetUser != msg.sender, "OCRBB_NO_SUICIDE");
        if ((ocr.startBlock() + STAKING_TIMELIMIT) >= block.number) {
            require(targetUser  != address(this), "OCRBB_TARGET_IS_STAKED");
        }

        ocr.kill(_targetId);
        emit PlayerKilled(_targetId, msg.sender);
    }

    function bribeToKill(
        uint256 _targetId
    ) external payable
    {
        OnChainRoyale ocr = OnChainRoyale(address(onChainRoyale));

        require(msg.value == BRIBE_PRICE, "OCRBB_INSUFFICIENT_FUNDS");
        require(ocr.balanceOf(msg.sender) > 0, "OCRBB_MUST_HAVE_ONE_FREE_PLAYER");

        StakingVault memory killerVault = stakingVaults[msg.sender];
        require(killerVault.balance > KILL_PRICE, "OCRBB_INSUFFICIENT_BALANCE");

        address targetUser = ocr.ownerOf(_targetId);
        require(targetUser != msg.sender, "OCRBB_NO_SUICIDE");
        if ((ocr.startBlock() + STAKING_TIMELIMIT) >= block.number) {
            require(targetUser != address(this), "OCRBB_TARGET_IS_STAKED");
        }

        ocr.kill(_targetId);

        BRIBE_PRICE = BRIBE_PRICE + (BRIBE_PRICE * 25) / 10000;
        emit BribePriceIncrease(BRIBE_PRICE, msg.sender);
        emit PlayerKilled(_targetId, msg.sender);
    }

    function stake(
        uint256[] memory _ids
    ) external
    {
        OnChainRoyale ocr = OnChainRoyale(address(onChainRoyale));

        require(ocr.currentStage() != OnChainRoyale.RoyaleStage.SIGNUPS, "OCRBB_STAKING_NOT_STARTED");
        require((ocr.startBlock() + STAKING_TIMELIMIT) > block.number, "OCRBB_STAKING_OVER");

        StakingVault memory userVault = stakingVaults[msg.sender];
        require(!userVault.isStaked, "OCRBB_ALREADY_STAKED");

        for (uint i;i<_ids.length;i++) {
            require(ocr.ownerOf(_ids[i]) == msg.sender, "OCRBB_NOT_OWNED");
            ocr.transferFrom(msg.sender, address(this), _ids[i]);
        }

        uint256 balance = userVault.balance;
        stakingVaults[msg.sender] = StakingVault({
            tokens: _ids,
            startBlock: block.number,
            balance: balance,
            isStaked: true
        });
    }

    function claim() external {
        StakingVault memory userVault = stakingVaults[msg.sender];
        require(userVault.isStaked, "OCRBB_NOT_STAKED");
        require((block.number - userVault.startBlock) > EMISSION_BLOCK_COUNT, "OCRBB_MUST_STAKE_FOR_AT_LEAST_ONE_ROUND");
        unchecked {
            uint256 rounds = ((block.number - userVault.startBlock) / EMISSION_BLOCK_COUNT) * userVault.tokens.length;
            uint256 balance = userVault.balance;
            uint256[] memory ids;
            stakingVaults[msg.sender] = StakingVault({
                tokens: ids,
                startBlock: block.number,
                balance: balance + (rounds*EMISSION_RATE),
                isStaked: false
            });
        }
    }

    function unstake() external {
        OnChainRoyale ocr = OnChainRoyale(address(onChainRoyale));
        
        StakingVault memory userVault = stakingVaults[msg.sender];
        require(userVault.isStaked, "OCRBB_NOT_STAKED");
        require((block.number - userVault.startBlock) > EMISSION_BLOCK_COUNT, "OCRBB_MUST_STAKE_FOR_AT_LEAST_ONE_ROUND");


        unchecked {
            uint256 rounds = ((block.number - userVault.startBlock) / EMISSION_BLOCK_COUNT) * userVault.tokens.length;
            uint256 balance = userVault.balance;
            uint256[] memory ids;
            for (uint i;i<userVault.tokens.length;i++) {
                ocr.transferFrom(address(this), msg.sender, userVault.tokens[i]);
            }
            stakingVaults[msg.sender] = StakingVault({
                tokens: ids,
                startBlock: block.number,
                balance: balance + (rounds*EMISSION_RATE),
                isStaked: false
            });
        }
    }

    function rewardAmount() external view returns (uint256 reward) {
        StakingVault memory userVault = stakingVaults[msg.sender];
        reward = 0;
        unchecked {
            if (userVault.isStaked && (userVault.startBlock < block.number) && (userVault.startBlock - block.number) > EMISSION_BLOCK_COUNT) {
                uint256 rounds = ((block.number - userVault.startBlock) / EMISSION_BLOCK_COUNT) * userVault.tokens.length;
                reward += (rounds * EMISSION_RATE);
            }
        }
        return reward;
    }

    function getStakedTokens(address _address) public view returns (uint256[] memory) {
        StakingVault memory vault = stakingVaults[_address];
        return vault.tokens;
    }

    function getStakeTime(address _address) public view returns (uint256) {
        unchecked {{
            StakingVault memory vault = stakingVaults[_address];
            if (vault.isStaked) {
                return block.number - vault.startBlock;
            }
            return 0;
        }}
    }

    function withdraw() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    function onERC721Received(
        address operator,
        address from,
        uint256 id,
        bytes calldata data
    ) external override returns (bytes4) {
        return this.onERC721Received.selector;
    }

}