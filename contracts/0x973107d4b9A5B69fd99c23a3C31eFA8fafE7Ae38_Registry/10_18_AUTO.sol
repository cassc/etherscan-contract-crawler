pragma solidity 0.8.6;


import "ERC777.sol";
import "Ownable.sol";


/**
* @title    AUTO contract
* @notice   The AUTO utility token which is used to stake in Autonomy and pay for
*           execution fees with
* @author   Quantaf1re (James Key)
*/
contract AUTO is ERC777, Ownable {

    constructor(
        string memory name,
        string memory symbol,
        address[] memory defaultOperators,
        address receiver,
        uint256 mintAmount
    ) ERC777(name, symbol, defaultOperators) Ownable() {
        _mint(receiver, mintAmount, "", "");
    }

    function mint(
        address receiver,
        uint amount,
        bytes memory userData,
        bytes memory operatorData
    ) external onlyOwner {
        _mint(receiver, amount, userData, operatorData);
    }
}