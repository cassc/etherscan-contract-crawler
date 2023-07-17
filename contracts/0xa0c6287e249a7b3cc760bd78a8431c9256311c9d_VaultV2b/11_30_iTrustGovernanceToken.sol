pragma solidity 0.7.6;

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20CappedUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/math/SafeMathUpgradeable.sol";

contract iTrustGovernanceToken is ERC20CappedUpgradeable, OwnableUpgradeable, PausableUpgradeable {

    using SafeMathUpgradeable for uint;

    address internal _treasuryAddress;
    uint internal _yearOneSupply;
    uint internal _yearTwoSupply;
    uint internal _yearThreeSupply;
    uint internal _yearFourSupply;
    uint internal _yearFiveSupply;
    
    function initialize(
        address payable treasuryAddress, 
        uint cap_,
        uint yearOneSupply, 
        uint yearTwoSupply, 
        uint yearThreeSupply, 
        uint yearFourSupply, 
        uint yearFiveSupply) initializer public {

        require(yearOneSupply.add(yearTwoSupply).add(yearThreeSupply).add(yearFourSupply).add(yearFiveSupply) == cap_);

        __ERC20_init("iTrust Governance Token", "$ITG");
        __ERC20Capped_init(cap_);
        __Ownable_init();
        __Pausable_init();

        _treasuryAddress = treasuryAddress;
        _yearOneSupply = yearOneSupply;
        _yearTwoSupply = yearTwoSupply;
        _yearThreeSupply = yearThreeSupply;
        _yearFourSupply = yearFourSupply;
        _yearFiveSupply = yearFiveSupply;

        
    }

    function mintYearOne() external onlyOwner {
        require(totalSupply() == 0);
        _mint(_treasuryAddress, _yearOneSupply);
    }

    function mintYearTwo() external onlyOwner {
        require(totalSupply() == _yearOneSupply);
        _mint(_treasuryAddress, _yearTwoSupply);
    }

    function mintYearThree() external onlyOwner {
        require(totalSupply() == _yearOneSupply.add(_yearTwoSupply));
        _mint(_treasuryAddress, _yearThreeSupply);
    }

    function mintYearFour() external onlyOwner {
        require(totalSupply() == _yearOneSupply.add(_yearTwoSupply).add(_yearThreeSupply));
        _mint(_treasuryAddress, _yearFourSupply);
    }

    function mintYearFive() external onlyOwner {
        require(totalSupply() == _yearOneSupply.add(_yearTwoSupply).add(_yearThreeSupply).add(_yearFourSupply));
        _mint(_treasuryAddress, _yearFiveSupply);
    }
}