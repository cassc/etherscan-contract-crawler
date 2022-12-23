// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
contract Afterglow is ERC20, Ownable {
    using SafeMath for uint256;
    mapping(address => bool) _whiteListed;
    bool private _dinnerOfChoiceMade = false; 
    bool private _massage = false; 
    bool private _mysteryGift1 = false; 
    bool private _mysteryGift2 = false; 
    modifier onlyWhitelisted() {
        require(
            _whiteListed[_msgSender()],
            "Whitelisted: caller is not whitelisted"
        );
        _;
    }

    function includeWhitelist(address addressToWhiteList)
        public
        virtual
        onlyOwner
    {
        _whiteListed[addressToWhiteList] = true;
    }

    function excludeWhitelist(address addressToExclude)
        public
        virtual
        onlyOwner
    {
        _whiteListed[addressToExclude] = false;
    }

    constructor() ERC20("Afterglow", "AG") {
        uint256 totalSupply = 1_000_000_000 * 1e18;  
        _mint(msg.sender, totalSupply);
        _whiteListed[msg.sender] = true;
    }

    receive() external payable {}

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        if (amount == 0) {
            super._transfer(from, to, 0);
            return;
        }  
        super._transfer(from, to, amount);
    }

    function setDinnerOfChoiceMade(bool flag) public onlyWhitelisted {
        _dinnerOfChoiceMade = flag;
    }
    function setMassage(bool flag) public onlyWhitelisted {
        _massage = flag;
    }
    function setMysteryGift1(bool flag) public onlyWhitelisted {
        _mysteryGift1 = flag;
    }
    function setMysteryGift2(bool flag) public onlyWhitelisted {
        _mysteryGift2 = flag;
    } 
    function getDinnerOfChoiceMade() public view returns (bool) {
        return _dinnerOfChoiceMade;
    }
    function getMassage() public view returns (bool) {
        return _massage;
    }
    function getMysteryGift1() public view returns (bool) {
        return _mysteryGift1;
    }
    function getMysteryGift2() public view returns (bool) {
        return _mysteryGift2;
    }
}