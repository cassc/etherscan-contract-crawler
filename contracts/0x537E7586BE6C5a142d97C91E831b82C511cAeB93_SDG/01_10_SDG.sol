// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IVesting.sol";
import "./utils/ReentrancyGuard.sol";
import "./libraries/TransferHelper.sol";

contract SDG is ERC20, ERC20Burnable, Ownable, VestingEvents, ReentrancyGuard {
    uint256 public Max_Token;
    uint256 decimalfactor;
    uint32 public startTime;
    uint8 public _decimals;

    struct UserData {
        uint256 totalAmount;
        uint256 claimedAmount;
        uint8 claims;
    }

    mapping(address => UserData) public userMapping;

    // addresses have to changed before deployment
    address public constant DEVELOPMENT_AND_MARKETING =
        0x8e36E428638b18eEfC69196C830D886fa1DB7965;
    address public constant EXECUTIVE_TEAM =
        0xdDcB33A9dF3453Ed48a4E0Cf51e4913425dF4494;
    address public constant ADVISOR =
        0x3C331AB27445Cf130348f1eeFE4C46151889D872;
    address public constant BOUNTIES_AND_AIRDROPS =
        0xB9Bce9F917CbDB1cC5d3E3060881F6a7d02F2Bf4;
    address public constant RESERVES =
        0xbcCA3dBefFDa5270DFdD1233c27f3285ADb5a32c;
    address public constant OTHERS = 0x729de1721E5ab16B3083E462028469e00eCe3b97;

    // Founders Addresses
    address public constant WALLET1 = 0x59a8f79cCb4db58495dE557F6Ff35E4287458F3a;
    address public constant WALLET2 =
        0x5f5982F8147629E23d6cE427c2601E20D2DD654D;
    address public constant WALLET3 =
        0x307377F77334d3D25697DA7560F6Ad9050a5eeED;
    address public constant WALLET4 =
        0x2B81d2c8E01A615ce1fd8eEee2a3aD89d5f74853;
    address public constant WALLET5 =
        0x910027dF02882f4289c563F836058d5Fa5Cfa45a;
    address public constant WALLET6 =
        0xF3e7b3e25fE6Da04233A82c9Ae97eF158BF6b4BD;
    address public constant WALLET7 =
        0xD19e92dB4BB7d5073Eae4Ed1db3616f189FD8b0E;
    address public constant WALLET8 =
        0x49504D89421F48D8EC687FF316C52747BAbB4d2E;
    address public constant WALLET9 =
        0x1bc70Bf006B47c65B8316FDb64d6acAD13958720;
    address public constant WALLET10 =
        0xBA70CEd29D73773fb5f902964e7Ff4EA5cD08ff8;
    address public constant WALLET11 =
        0xC39b6A51b59eA71fca96Ca316187CdC8AB5e417c;

    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimal
    ) ERC20(_name, _symbol) {
        _decimals = _decimal;
        decimalfactor = 10**uint256(_decimals);
        Max_Token = 4_040_000_000_000 * decimalfactor;
        startTime = uint32(block.timestamp);

        // Team Token Minting
        mint(DEVELOPMENT_AND_MARKETING, (323_200_000_000 * decimalfactor));
        mint(EXECUTIVE_TEAM, (242_400_000_000 * decimalfactor));
        mint(ADVISOR, (80_800_000_000 * decimalfactor));
        mint(BOUNTIES_AND_AIRDROPS, (40_400_000_000 * decimalfactor));
        mint(RESERVES, (202_000_000_000 * decimalfactor));
        mint(address(this), (1_535_200_000_000 * decimalfactor));
        registerUser((242_400_000_000 * decimalfactor), OTHERS);

        // Founder Token Register for Claims
        registerUser((242_400_000_000 * decimalfactor), WALLET1);
        registerUser((155_136_000_000 * decimalfactor), WALLET2);
        registerUser((90_496_000_000 * decimalfactor), WALLET3);
        registerUser((16_160_000_000 * decimalfactor), WALLET4);
        registerUser((271_488_000_000 * decimalfactor), WALLET5);
        registerUser((161_600_000_000 * decimalfactor), WALLET6);
        registerUser((80_800_000_000 * decimalfactor), WALLET7);
        registerUser((129_280_000_000 * decimalfactor), WALLET8);
        registerUser((64_640_000_000 * decimalfactor), WALLET9);
        registerUser((40_400_000_000 * decimalfactor), WALLET10);
        registerUser((40_400_000_000 * decimalfactor), WALLET11);
    }

    function mint(address to, uint256 amount) public onlyOwner {
        require(
            Max_Token >= (totalSupply() + amount),
            "ERC20: Max Token limit exceeds"
        );
        _mint(to, amount);
    }

    function decimals() public view virtual override returns (uint8) {
        return _decimals;
    }

    /* =============== Register The Address For Claiming ===============*/
    function registerUser(uint256 _amount, address _to) internal {
        UserData storage user = userMapping[_to];
        user.totalAmount = _amount;
    }

    /* =============== Token Claiming Functions =============== */
    function claimTokens() external nonReentrant {
        require(
            userMapping[msg.sender].totalAmount > 0,
            "User is not register with any vesting"
        );

        (uint256 _amount, uint8 _claimCount) = tokensToBeClaimed(msg.sender);

        require(_amount > 0, "Amount should be greater then Zero");

        UserData storage user = userMapping[msg.sender];
        user.claimedAmount += _amount;
        user.claims = _claimCount;

        TransferHelper.safeTransfer(address(this), msg.sender, _amount);

        emit ClaimedToken(msg.sender, user.claimedAmount, _claimCount);
    }

    /* =============== Tokens to be claimed =============== */

    function tokensToBeClaimed(address to)
        public
        view
        returns (uint256, uint8)
    {
        uint256 monthValue = 30 days;
        UserData memory user = userMapping[to];

        require(
            block.timestamp >= (startTime + (12 * monthValue)),
            "You can't claim before Vesting start time"
        );

        require(
            user.totalAmount > user.claimedAmount,
            "You already claimed all the tokens."
        );

        uint32 time = uint32(block.timestamp - (startTime + (12 * monthValue)));
        uint8 claimCount = uint8((time / monthValue) + 1);

        if (claimCount > 10) {
            claimCount = 10;
        }

        require(
            claimCount > user.claims,
            "You already claimed for this month."
        );

        uint256 toBeTransfer;
        if (claimCount == 10) {
            toBeTransfer = user.totalAmount - user.claimedAmount;
        } else {
            for (uint8 i = user.claims; i < claimCount; i++) {
                toBeTransfer += (user.totalAmount * 1000) / 10000;
            }
        }

        return (toBeTransfer, claimCount);
    }
}