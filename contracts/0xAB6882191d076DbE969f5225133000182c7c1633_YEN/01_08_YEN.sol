// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;
import "./libs/ERC20Burnable.sol";
import "./interfaces/IUniswapFactory.sol";
import "./interfaces/IUniswapV2Pair.sol";

contract YEN is ERC20Burnable {
    event Mint(address indexed person, uint256 index);
    event Claim(address indexed person, uint256 amount);
    event Stake(address indexed person, uint256 amount);
    event WithdrawStake(address indexed person, uint256 amount);
    event WithdrawReward(address indexed person, uint256 amount);

    struct Block {
        uint128 persons;
        uint128 mints;
    }

    struct Person {
        uint32[] blockList;
        uint128 blockIndex;
        uint128 stakes;
        uint96 rewards;
        uint160 lastPerStakeRewards;
    }

    uint256 public constant halvingBlocks = ((60 * 60 * 24) / 12) * 30;
    // uint256 public constant halvingBlocks = ((60 * 60 * 24) / 12) * 1;
    uint256 public lastBlock = block.number;
    uint256 public halvingBlock = lastBlock + halvingBlocks;
    uint256 public blockMints = 100 * 10**18;

    uint256 public stakes = 1;
    uint256 public perStakeRewards;

    IERC20 public immutable token = IERC20(address(this));
    IUniswapV2Pair public immutable pair =
        IUniswapV2Pair(
            IUniswapV2Factory(0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f).createPair(
                0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2,
                address(this)
            )
        );
    // IUniswapV2Pair public immutable pair =
    //     IUniswapV2Pair(
    //         IUniswapV2Factory(0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f).createPair(
    //             0xB4FBF271143F4FBf7B91A5ded31805e42b2208d6,
    //             address(this)
    //         )
    //     );

    mapping(uint256 => Block) public blockMap;
    mapping(address => Person) public personMap;

    constructor() ERC20("yen.cool", "YEN") {}

    /* ================ UTIL FUNCTIONS ================ */

    modifier _checkHalving() {
        if (block.number >= halvingBlock) {
            blockMints /= 2;
            halvingBlock += halvingBlocks;
        }
        _;
    }

    modifier _checkReward() {
        if (personMap[msg.sender].lastPerStakeRewards != perStakeRewards) {
            personMap[msg.sender].rewards = uint96(getRewards(msg.sender));
            personMap[msg.sender].lastPerStakeRewards = uint160(perStakeRewards);
        }
        _;
    }

    function _addPerStakeRewards(uint256 adds) internal {
        unchecked {
            perStakeRewards += (adds * 10**18) / stakes;
        }
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal override {
        unchecked {
            require(sender != address(0), "ERC20: transfer from the zero address");
            require(recipient != address(0), "ERC20: transfer to the zero address");

            _beforeTokenTransfer(sender, recipient, amount);

            uint256 senderBalance = _balances[sender];
            require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");

            _balances[sender] = senderBalance - amount;

            uint256 fees;
            if (sender != address(this)) {
                fees = amount / 1000;
                _balances[address(this)] += fees;
                emit Transfer(sender, address(this), fees);
                uint256 burnFees = fees / 2;
                _burn(address(this), burnFees);
                _addPerStakeRewards(fees - burnFees);
            }

            uint256 recipients = amount - fees;
            _balances[recipient] += recipients;
            emit Transfer(sender, recipient, recipients);

            _afterTokenTransfer(sender, recipient, amount);
        }
    }

    /* ================ VIEW FUNCTIONS ================ */

    function getMints() public view returns (uint256) {
        unchecked {
            return (block.number - lastBlock) * blockMints;
        }
    }

    function getClaims(address sender) public view returns (uint256) {
        Person memory person = personMap[sender];
        uint256 claims;
        for (uint256 i = 0; i < person.blockIndex; i++) {
            Block memory _block = blockMap[person.blockList[i]];
            claims += _block.mints / _block.persons;
        }
        return claims;
    }

    function getRewards(address person) public view returns (uint256) {
        unchecked {
            return
                (personMap[person].stakes * (perStakeRewards - personMap[person].lastPerStakeRewards)) /
                10**18 +
                personMap[person].rewards;
        }
    }

    function getPersonBlockList(address person) external view returns (uint32[] memory) {
        uint32[] memory blockList = new uint32[](personMap[person].blockIndex);
        for (uint256 i = 0; i < personMap[person].blockIndex; i++) {
            blockList[i] = personMap[person].blockList[i];
        }
        return blockList;
    }

    /* ================ TRANSACTION FUNCTIONS ================ */

    function mint() external _checkHalving {
        require(msg.sender == tx.origin, "no magic");
        if (block.number != lastBlock) {
            uint256 mints = getMints();
            _mint(address(this), mints);
            blockMap[block.number].mints = uint128(mints / 2);
            lastBlock = block.number;
            _addPerStakeRewards(blockMap[block.number].mints);
        }
        Person storage person = personMap[msg.sender];
        if (person.blockList.length == person.blockIndex) {
            person.blockList.push(uint32(block.number));
        } else {
            person.blockList[person.blockIndex] = uint32(block.number);
        }
        emit Mint(msg.sender, blockMap[block.number].persons);
        blockMap[block.number].persons++;
        person.blockIndex++;
    }

    function claim() external {
        Person memory person = personMap[msg.sender];
        require(person.blockList[person.blockIndex - 1] != block.number, "mint claim cannot in sample block!");
        uint256 claims = getClaims(msg.sender);
        personMap[msg.sender].blockIndex = 0;
        token.transfer(msg.sender, claims);
        emit Claim(msg.sender, claims);
    }

    function stake(uint256 amount) external _checkReward {
        pair.transferFrom(msg.sender, address(this), amount);
        personMap[msg.sender].stakes += uint128(amount);
        stakes += amount;
        emit Stake(msg.sender, amount);
    }

    function withdrawStake(uint256 amount) public _checkReward {
        require(amount <= personMap[msg.sender].stakes, "amount cannot over stakes!");
        personMap[msg.sender].stakes -= uint128(amount);
        stakes -= amount;
        pair.transfer(msg.sender, amount);
        emit WithdrawStake(msg.sender, amount);
    }

    function withdrawReward() public _checkReward {
        uint256 rewards = personMap[msg.sender].rewards;
        personMap[msg.sender].rewards = 0;
        token.transfer(msg.sender, rewards);
        emit WithdrawReward(msg.sender, rewards);
    }

    function exit() external {
        withdrawStake(personMap[msg.sender].stakes);
        withdrawReward();
    }
}