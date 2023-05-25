// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * A number of codes are defined as error messages.
 * Codes are resembling HTTP statuses. This is the structure
 * CODE:SHORT
 * Where CODE is a number and SHORT is a short word or phrase
 * describing the condition
 * CODES:
 * 100  contract status: open/closed, depleted. In general for any flag
 *     causing the mint too not to happen.
 * 200  parameters validation errors, like zero address or wrong values
 * 300  User payment amount errors like not enough funds.
 * 400  Contract amount/availability errors like not enough tokens or empty vault.
 * 500  permission errors, like not whitelisted, wrong address, not the owner.
 */
contract BAPMethane is ERC20, Ownable {
    uint8 public constant decimalPlaces = 0;
    uint256 public mintingMin = 10;
    uint256 public maxSupply = 560000000;
    uint256 public constant treasuryLiquidity = 22400000;
    uint256 public burned;
    address public treasuryWallet;
    bool public open = false;
    address public orchestrator;
    address public vestingManager;
    mapping(address => uint256) public claims;

    constructor(address _treasuryWallet) ERC20("BAP Methane", "METH") {
        treasuryWallet = _treasuryWallet;
        // Fund treasury immediately
        require(
            treasuryWallet != address(0),
            "Treasury Wallet cannot be Address Zero"
        );
        _mint(treasuryWallet, treasuryLiquidity);
    }

    function airdrop(address wallet, uint256 tokenAmount) public onlyOwner {
        require(open, "100:CLOSED");
        require(_verifyMethAvailability(tokenAmount), "400:EXCEEDS_SUPPLY");
        _mint(wallet, tokenAmount);
        claims[wallet] += tokenAmount;
    }

    function claim(address wallet, uint256 tokenAmount) public {
        require(open, "100:CLOSED");
        require(verifyOrigin(), "500:UNAUTHORIZED");
        require(mintingMin <= tokenAmount, "300:INSUFFICIENT_METH");
        require(_verifyMethAvailability(tokenAmount), "400:EXCEEDS_SUPPLY");
        _mint(wallet, tokenAmount);
        claims[wallet] += tokenAmount;
    }

    function decimals() public view virtual override returns (uint8) {
        return decimalPlaces;
    }

    function pay(uint256 paymentAmount, uint256 fee) public {
        require(open, "100:CLOSED");
        require(orchestrator == msg.sender, "500:UNAUTHORIZED");
        require(balanceOf(tx.origin) >= paymentAmount, "300:INSUFFICIENT_METH");
        uint256 _fee = fee;
        // Protect unsingned operation
        if (fee > paymentAmount) {
            _fee = paymentAmount;
        }
        uint256 toBurn = paymentAmount - _fee;
        _transfer(tx.origin, treasuryWallet, _fee);
        if (toBurn > 0) {
            _burn(tx.origin, toBurn);
            burned += toBurn;
        }
    }

    function verifyOrigin() internal view returns (bool) {
        return msg.sender == orchestrator || msg.sender == vestingManager;
    }

    function setMintingMin(uint256 min) public onlyOwner {
        require(min > 0, "200:INVALID_PARAM");
        mintingMin = min;
    }

    function setOpen(bool _open) public onlyOwner {
        open = _open;
    }

    function setMaxSupply(uint256 _maxSupply) public onlyOwner {
        require(_maxSupply > burned + totalSupply(), "200:INVALID_PARAM");
        maxSupply = _maxSupply;
    }

    function setTreasuryWallet(address wallet) public onlyOwner {
        require(wallet != address(0), "200:ZERO_ADDRESS");
        treasuryWallet = wallet;
    }

    function setOrchestrator(address contractAddress) external onlyOwner {
        require(contractAddress != address(0), "200:ZERO_ADDRESS");
        orchestrator = contractAddress;
    }

    function setVestingManager(address contractAddress) external onlyOwner {
        require(contractAddress != address(0), "200:ZERO_ADDRESS");
        vestingManager = contractAddress;
    }

    function _verifyMethAvailability(uint256 tokenAmount)
        internal
        view
        returns (bool)
    {
        // To burn a token, modifies the total supply. Therefore, we need to use the burn tracker
        return (tokenAmount + burned + totalSupply()) < maxSupply;
    }
}