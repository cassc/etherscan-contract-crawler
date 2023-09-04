pragma solidity ^0.8.0;
import '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import '@openzeppelin/contracts/access/Ownable.sol';

contract GoToken is  Ownable, ERC20 {
    /**
     * @notice Constructs the Basis Cash ERC-20 contract.
     */
    constructor()  ERC20('LetsGoDay Game Olympic', 'LGO')  {
        _mint(msg.sender, 1000000000 * 1e18);
    }

    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    function mint(uint256 value) public onlyOwner{
        require((value > 0), "value range error");
        _mint(msg.sender, value);
    }

}