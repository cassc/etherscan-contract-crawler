// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./RobotokenNftSale.sol";

contract RobotokenNft is RobotokenNftSale {
    string public constant PROVENANCE =
        "ab8a4e5f66321a666b1359363e567dae23d5c0a308a4e5887784a2d853b9cc92";
    address[] public TEAM = [
        0xCE01b1a320b2BD5ce016daD20476e76BD43fA145,
        0x215d8B3A2AB2a12059556864E9bEfdc5853CeD86
    ];

    // Mint
    uint256[MAX_SUPPLY] private _indices;
    uint256 private _randomNonce;

    // RefRewards
    uint256 public constant refPercent = 10;
    uint256 public refRewardsTotal;
    uint256 public refRewardsPaid;
    mapping(address => uint256) public refRewards;

    event RefRewardsAccrued(
        address indexed referrer,
        address indexed referral,
        uint256 amount
    );
    event RefRewardsWithdrawed(address indexed referrer, uint256 amount);
    event Withdrawed(address indexed payee, uint256 amount);

    constructor(
        string memory contractURI_,
        string memory baseTokenURI_,
        string memory notRevealedURI_,
        address proxyRegistry_
    )
        ERC721(
            "Robotoken",
            "ROBO",
            contractURI_,
            baseTokenURI_,
            notRevealedURI_,
            proxyRegistry_
        )
    {
        _indices[11] = MAX_SUPPLY - 1;
        _mint(0x492c9D011367089Fef11F5A6b864c52c868e2cFE, 12);
    }

    function mintAirdrop() external {
        require(isAirdropActive(), "Airdrop is not active");
        require(airdropWhitelist[_msgSender()], "Not whitelisted");
        require(!isAirdropLimit(_msgSender()), "Limits exceeded");
        _makeAirdropStats(_msgSender());
        _internalMint(_msgSender());
    }

    function mintPresale(uint256 count, address referrer) external payable {
        require(isPresaleActive(), "Presale is not active");
        require(presaleWhitelist[_msgSender()], "Not whitelisted");
        require(!isSaleLimit(count), "Limits exceeded");
        require(msg.value >= presalePrice * count, "Wrong value provided");
        _internalMintBatch(_msgSender(), count);
        _makeRefRewards(referrer, _msgSender(), msg.value);
    }

    function mintSale(uint256 count, address referrer) external payable {
        require(isSaleActive(), "Sale is not active");
        require(!isSaleLimit(count), "Limits exceeded");
        require(msg.value >= salePrice * count, "Wrong value provided");
        _internalMintBatch(_msgSender(), count);
        _makeRefRewards(referrer, _msgSender(), msg.value);
    }

    // RefRewards
    function _makeRefRewards(
        address referrer,
        address referral,
        uint256 amount
    ) private {
        if (referrer != address(0)) {
            uint256 rewards = (amount * refPercent) / 100;
            refRewards[referrer] += rewards;
            refRewardsTotal += rewards;
            emit RefRewardsAccrued(referrer, referral, rewards);
        }
    }

    function withdrawRefRewards(address referrer) external {
        uint256 rewards = refRewards[referrer];
        refRewards[referrer] = 0;
        refRewardsPaid += rewards;
        _sendEth(referrer, rewards);
        emit RefRewardsWithdrawed(referrer, rewards);
    }

    // Mint
    function _internalMintBatch(address account, uint256 count) private {
        for (uint256 i = 0; i < count; i++) {
            _internalMint(account);
        }
    }

    function _internalMint(address account) private returns (uint256 tokenId) {
        tokenId = _randomIndex();
        _mint(account, tokenId);
    }

    function _randomIndex() private returns (uint256) {
        uint256 totalSize = MAX_SUPPLY - totalSupply();
        uint256 index = uint256(
            keccak256(
                abi.encodePacked(
                    _randomNonce++,
                    msg.sender,
                    block.difficulty,
                    block.timestamp
                )
            )
        ) % totalSize;
        uint256 value = 0;
        if (_indices[index] != 0) {
            value = _indices[index];
        } else {
            value = index;
        }

        // Move last value to selected position
        if (_indices[totalSize - 1] == 0) {
            // Array position not initialized, so use position
            _indices[index] = totalSize - 1;
        } else {
            // Array position holds a value so use that
            _indices[index] = _indices[totalSize - 1];
        }
        return value + 1;
    }

    // Withdraw
    function withdraw() external {
        uint256 amount = address(this).balance -
            (refRewardsTotal - refRewardsPaid);
        for (uint256 i = 0; i < TEAM.length; i++) {
            uint256 share = (amount * 50) / 100;
            _sendEth(TEAM[i], share);
            emit Withdrawed(TEAM[i], share);
        }
    }

    function _sendEth(address recipient, uint256 amount) private {
        (bool success, ) = recipient.call{value: amount}("");
        require(success, "ETH_TRANSFER_FAILED");
    }
}