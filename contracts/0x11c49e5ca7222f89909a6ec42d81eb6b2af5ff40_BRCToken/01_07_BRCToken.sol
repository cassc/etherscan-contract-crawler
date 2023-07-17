// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "../interfaces/IEMEFactory.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";

contract BRCToken is ERC20, Ownable {
    using SafeMath for uint256;

    uint256 public constant BASE_RATIO = 10**18;
    uint256 public constant MAX_SALE_FEE = (3 * BASE_RATIO) / 100;
    uint256 public immutable MAX_BURN_AMOUNT;
    mapping(address => bool) private minner;
    mapping(address => bool) public pairs;
    mapping(address => bool) public whitelist;
    uint256 public remaining;
    address public vault;
    uint256 public burnFeePercentOnSale;
    uint256 public teamFeePercentOnSale;

    event NewBurnFeePercent(uint256 oldFee, uint256 newFee);
    event NewTeamFeePercent(uint256 oldFee, uint256 newFee);
    event AddPair(address pair);
    event DelPair(address pair);
    event AddWhitelist(address account);
    event DelWhitelist(address account);
    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals,
        uint256 _maxSupply,
        address _vault
    ) ERC20(_name, _symbol) {
        _setupDecimals(_decimals);
        remaining = _maxSupply;
        vault = _vault;
        MAX_BURN_AMOUNT = remaining.sub(20000000000 * (10**_decimals));
        burnFeePercentOnSale = BASE_RATIO.mul(15).div(1000);
        emit NewBurnFeePercent(0, BASE_RATIO.mul(15).div(1000));
        teamFeePercentOnSale = BASE_RATIO.mul(15).div(1000);
        emit NewTeamFeePercent(0, BASE_RATIO.mul(15).div(1000));
        require(
            MAX_SALE_FEE >= burnFeePercentOnSale.add(teamFeePercentOnSale),
            "fee overflow"
        );
    }

    function setMinner(address _minner, bool enable) external onlyOwner {
        minner[_minner] = enable;
    }

    function isMinner(address account) public view returns (bool) {
        return minner[account];
    }

    modifier onlyMinner() {
        require(isMinner(msg.sender), "caller is not minter");
        _;
    }

    function setVault(address _vault) external onlyOwner {
        vault = _vault;
    }

    function setBurnFeePercentOnSale(uint256 percent) external onlyOwner {
        require(
            MAX_SALE_FEE >= teamFeePercentOnSale.add(percent),
            "fee overflow"
        );
        emit NewBurnFeePercent(burnFeePercentOnSale, percent);
        burnFeePercentOnSale = percent;
    }

    function setTeamFeePercentOnSale(uint256 percent) external onlyOwner {
        require(
            MAX_SALE_FEE >= burnFeePercentOnSale.add(percent),
            "fee overflow"
        );
        emit NewTeamFeePercent(teamFeePercentOnSale, percent);
        teamFeePercentOnSale = percent;
    }

    function expectPair(
        IEMEFactory _factory,
        address _tokenA,
        address _tokenB
    ) public pure returns (address pair) {
        (address token0, address token1) = _tokenA < _tokenB
            ? (_tokenA, _tokenB)
            : (_tokenB, _tokenA);
        pair = address(
            uint160(
                uint256(
                    keccak256(
                        abi.encodePacked(
                            hex"ff",
                            _factory,
                            keccak256(abi.encodePacked(token0, token1)),
                            _factory.INIT_CODE_PAIR_HASH()
                        )
                    )
                )
            )
        );
    }

    function addPairByFactory(IEMEFactory _factory, address _token)
        external
        onlyOwner
    {
        address pair = expectPair(_factory, address(this), _token);
        pairs[pair] = true;
        emit AddPair(pair);
    }

    function addPair(address _pair) external onlyOwner {
        pairs[_pair] = true;
        emit AddPair(_pair);
    }

    function delPair(address _pair) external onlyOwner {
        delete pairs[_pair];
        emit DelPair(_pair);
    }

    function addWhitelist(address _addr) external onlyOwner {
        whitelist[_addr] = true;
        emit AddWhitelist(_addr);
    }

    function delWhitelist(address _addr) external onlyOwner {
        delete whitelist[_addr];
        emit DelWhitelist(_addr);
    }

    function mint(address to, uint256 value) external onlyMinner {
        require(remaining >= value, "Inadequate supply");
        remaining = remaining.sub(value);
        _mint(to, value);
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override {
        if (pairs[to] && !whitelist[from] && !whitelist[to]) {
            amount = calculateFee(from, amount);
        }
        super._transfer(from, to, amount);
    }

    function calculateFee(
        address from,
        uint256 amount
    ) internal returns (uint256) {
        uint256 burnFee = amount.mul(burnFeePercentOnSale).div(BASE_RATIO);
        if (balanceOf(address(0xdead)).add(burnFee) >= MAX_BURN_AMOUNT) {
            if (balanceOf(address(0xdead)) < MAX_BURN_AMOUNT) {
                burnFee = MAX_BURN_AMOUNT.sub(balanceOf(address(0xdead)));
            } else {
                burnFee = 0;
            }
        }
        if (burnFee > 0) {
            amount = amount.sub(burnFee);
            super._transfer(from, address(0xdead), burnFee);
        }
        uint256 teamFee = amount.mul(teamFeePercentOnSale).div(BASE_RATIO);
        if (teamFee > 0) {
            amount = amount.sub(teamFee);
            super._transfer(from, vault, teamFee);
        }

        return amount;
    }
}