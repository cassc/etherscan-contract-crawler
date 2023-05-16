pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/utils/Address.sol";

contract BDSM is Ownable, ERC20 {
    using EnumerableSet for EnumerableSet.AddressSet;

    bool public privateSale;
    uint256 public maxPurchaseAmount;
    address public uniswapV2Pair;
    EnumerableSet.AddressSet private allowedAddresses;

    constructor(uint256 _totalSupply) ERC20("Depe Society", "BDSM") {
        _mint(
            address(0xb5268860838E6aC267ed8D976059d6E9b88E089C),
            660_000_000_000_000_000_000_000_000
        );
        _mint(
            address(0xF8d18e3edBcB3f084C126E5240E8416b5DF45Df1),
            660_000_000_000_000_000_000_000_000
        );
        _mint(
            address(0x12C9b4e92277BBA4C069139D6c71DE98DE1b3335),
            660_000_000_000_000_000_000_000_000
        );
        _mint(
            address(0xeFcfFD23BA7f0b71848ddaaeCdAD4BB8F6948BA7),
            379_952_814_052_650_000_000_000_000
        );
        _mint(
            address(0x07dD8451d27eBB6442395A512A081dAfC6791850),
            270_932_636_258_265_000_000_000_000
        );
        _mint(
            address(0xB715656dA71ee46E86175C1406E48a34bD49724d),
            197_656_654_707_582_000_000_000_000
        );
        _mint(
            address(0x21d21386462D1a6ae2c841Eb0f1aFfF2eC2B5656),
            185_917_405_404_077_000_000_000_000
        );
        _mint(
            address(0x52B22Be335005F00546276B85DF46519ee08338A),
            158_807_945_943_405_000_000_000_000
        );
        _mint(
            address(0xe07048CF03f82e4A9f37A4F294F36E7Cb0cEAF34),
            157_657_473_189_852_000_000_000_000
        );
        _mint(
            address(0x8feE41eebB2572E8c0820bbE02a16dE358BA214C),
            146_452_565_124_600_000_000_000_000
        );
        _mint(
            address(0x496f4dE4e95c4a24a50e311bF8F3a39C073e1a46),
            103_886_685_697_771_000_000_000_000
        );
        _mint(
            address(0x6B9eb6e3775351cFea22ef6AE10F2A741cdD586F),
            92_055_556_466_822_200_000_000_000
        );
        _mint(
            address(0x87CC39e35E0910fDD5017dCb2D4662B3B4C05E52),
            78_931_215_007_892_900_000_000_000
        );
        _mint(
            address(0x908c44D464D022F2C44FC1e097224998580ba498),
            68_920_273_396_165_000_000_000_000
        );
        _mint(
            address(0xabb6ed6e89101871adBC0E71453FFb4622caff08),
            66_966_683_322_840_800_000_000_000
        );
        _mint(
            address(0x77cCC682D8AD78c4207CAB7f0d148E43bFa186dE),
            65_421_617_464_075_300_000_000_000
        );
        _mint(
            address(0xe45B053DcF8f520bA6b1814cE9259365B2d3C111),
            44_871_352_557_589_100_000_000_000
        );
        _mint(
            address(0x287bDF8c332D44Bb015F8b4dEb6513010c951f39),
            44_007_535_342_332_500_000_000_000
        );
        _mint(
            address(0x7588A6Cd8d70ecf35a005ae6334C2De1E967b6D6),
            36_107_971_208_727_700_000_000_000
        );
        _mint(
            address(0xdC23d1367d84AAd2359e3b8C8579C29E3707E309),
            34_086_275_658_774_900_000_000_000
        );
        _mint(
            address(0x367ff64dA0668D86E7Ac5d43dD9459Fd4CE381d6),
            33_403_783_993_855_400_000_000_000
        );
        _mint(
            address(0xF73c935815908Ad9a056fc50269f95d8bA032e9d),
            31_675_281_398_330_600_000_000_000
        );
        _mint(
            address(0xf74494c3Ca542D3DDa4209FAB1ebba1BC8F57487),
            31_322_979_712_016_700_000_000_000
        );
        _mint(
            address(0x18235bA397811cfcF96516EE9649E6288B0BA90F),
            27_585_726_114_200_700_000_000_000
        );
        _mint(
            address(0xdCb9b454e13788E33fB07281C974439738faFf36),
            26_099_282_049_618_600_000_000_000
        );
        _mint(
            address(0x35e3CdFa6E176110f75f64dA2F7E47A371782cF5),
            20_187_093_956_303_800_000_000_000
        );
        _mint(
            address(0x0695C06aF6A583061d92f47671Df1b6818a015aC),
            18_552_030_512_403_300_000_000_000
        );
        _mint(
            address(0x4D64bb6Ee3330B3acb747643872dAa414b14775d),
            14_893_091_452_005_300_000_000_000
        );
        _mint(
            address(0xA633F0ab63c24a7218E1efA31fE66102a0066fb0),
            9_462_318_583_365_150_000_000_000
        );
        _mint(
            address(0xB0A7c5bEA4A42C21EDB7C0304c284f4e0B473f6f),
            6_239_807_015_284_330_000_000_000
        );
        _mint(
            address(0xae195e368f51c38636cDE344FB5A238D575B4FD7),
            4_923_096_661_356_390_000_000
        );
        _mint(
            address(0x34d05Abb475c6F65F70fF6427edA8dB9CE4D40ad),
            206_411_602_103_834_000_000_000_000
        );
        _mint(
            address(0xd7e5143234c6fD0B76caAF3f0D0e172A7a8e3Ebb),
            262_989_293_329_616_000_000_000_000
        );
        _mint(
            address(0xDdB46043d8afb5476Cb431A7E8747dc444aED590),
            75_502_908_596_115_700_000_000_000
        );
        _mint(
            address(0x534b8531e362Da97D808ba2ab3959fa2597BeF11),
            34_817_762_816_030_700_000_000_000
        );
        _mint(
            address(0x8c86c59bE7eBe05BF4abBeBA2d565138d5368299),
            8_429_735_128_229_550_000_000_000
        );
        _mint(
            address(0x90598fAEcb13b32B33E0D2aD07E74eACE9AFd64F),
            155_720_985_543_442_000_000_000_000
        );
        _mint(
            address(0x564154FD6948c2882a00D72E19e70d1D84E06115),
            330_000_000_000_000_000_000_000_000
        );

        _mint(_msgSender(), _totalSupply - totalSupply());
    }

    function setPrivateSale(
        bool _private,
        address _uniswapV2Pair,
        uint256 _maxHoldingAmount,
        address[] calldata _allowedAddresses
    ) external onlyOwner {
        privateSale = _private;
        uniswapV2Pair = _uniswapV2Pair;
        maxPurchaseAmount = _maxHoldingAmount;

        for (uint256 i; i < _allowedAddresses.length; i++) {
            allowedAddresses.add(_allowedAddresses[i]);
        }
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override {
        if (uniswapV2Pair == address(0)) {
            require(!Address.isContract(address(this)) || from == owner() || to == owner(), "trading not started");
            return;
        }

        require(
            !privateSale ||
                allowedAddresses.contains(from) ||
                allowedAddresses.contains(to),
            "private sale"
        );

        if (privateSale) {
            if (from == uniswapV2Pair) {
                require(
                    balanceOf(to) + amount <= maxPurchaseAmount,
                    "purchase capped"
                );
            }
        }
    }
}