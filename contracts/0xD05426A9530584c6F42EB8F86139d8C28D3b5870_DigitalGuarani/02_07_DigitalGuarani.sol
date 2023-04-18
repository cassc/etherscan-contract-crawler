// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.4; 

// Import necessary contracts from the OpenZeppelin library
import "./IERC20.sol";
import "./ERC20.sol";
import "./Ownable.sol";

// Define the DigitalGuarani contract, which inherits from the ERC20 and Ownable contracts
contract DigitalGuarani is ERC20, Ownable {

    // Declare the USD stablecoins or US CBDC token contract that will be used as collateral
    IERC20 public usd;
    
    // Define the pegged price, representing the exchange rate of PYG to USD stablecoins or US CBDC
    uint256 public peggedPrice; // PYG per USD stablecoins or US CBDC

    // Define events for contract activity tracking
    event PeggedPriceUpdated(uint256 newPeggedPrice);
    event Minted(address to, uint256 amount);
    event Burned(address from, uint256 amount);
    event Deposited(address depositor, uint256 usdAmount, uint256 pygAmount);
    event Withdrawn(address withdrawer, uint256 pygAmount, uint256 usdAmount);

    // Constructor function initializes the contract with the USD stablecoins or US CBDC token contract address and the initial pegged price
    constructor(address _usd, uint256 _peggedPrice) ERC20("Digital Guarani", "PYG") {
        usd = IERC20(_usd);
        peggedPrice = _peggedPrice;
    }

    // Function to update the pegged price, can only be called by the contract owner
    function setPeggedPrice(uint256 _newPeggedPrice) external onlyOwner {
        peggedPrice = _newPeggedPrice;
        emit PeggedPriceUpdated(peggedPrice);
    }

    // Function to mint PYG stablecoins, can only be called by the contract owner
    function mint(address to, uint256 amount) external onlyOwner {
        _mint(to, amount);
        emit Minted(to, amount);
    }

    // Function to burn PYG stablecoins, can only be called by the contract owner
    function burn(address from, uint256 amount) external onlyOwner {
        _burn(from, amount);
        emit Burned(from, amount);
    }

    // Function for users to deposit USD stablecoins or US CBDC and receive PYG stablecoins
    function deposit(uint256 usdAmount) external {
        uint256 pygAmount = usdAmount * peggedPrice;

        // Transfer USD stablecoins or US CBDC from the user to the contract
        usd.transferFrom(msg.sender, address(this), usdAmount * (10 ** uint256(6)));

        // Mint PYG stablecoins and send them to the user
        _mint(msg.sender, pygAmount * (10 ** uint256(decimals())));
        emit Deposited(msg.sender, usdAmount, pygAmount);
    }

    // Function for users to redeem their PYG stablecoins for USD stablecoins or US CBDC
    function withdraw(uint256 pygAmount) external {
        uint256 usdAmount = pygAmount / peggedPrice;

        // Burn the PYG stablecoins from the user's account
        _burn(msg.sender, pygAmount * (10 ** uint256(decimals())));

        // Transfer USD stablecoins or US CBDC from the contract to the user
        usd.transfer(msg.sender, usdAmount * (10 ** uint256(6)));
        emit Withdrawn(msg.sender, pygAmount, usdAmount);
    }
}

