// DuckFrens (www.duckfrens.com) - $BREAD Token

// MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWWWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMW0O0KXNWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMMMMMMMMMNK0OxxOOOO00KKNWMMMMMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMMMMMMMNKOO0KXXXXXXXK000K0KNMMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMMMMMNKOOKXXXXXXXXXXXXXXNXK0KNMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMMMN0OOKXXXXXXXXXXXXXXXXXNNN0OXWMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMMXkdOXXXXXXXXXXXXXXXXXXXXXNN0OXWMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMXkdOKXXXXXXXNNNNXXXXXXXXXXXXXkkNMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMWOdOKXXXXXKkddkOKNNXXXXXXXXX0dodkXMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMKxkKXXXXX0d;;oxld0XXXXXXXXXXkclxd0MMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMXxdkKXXXXXk:,;ooc:dKXXXXXXXXXOc;;cOWMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMXddOKXXXXXk:,,,,,;dKXX0OOkxxxdl:cdO0XWMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMXdoOKXXXXX0xlcccldOKkdoolllooooooodokNMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMNkdk0KXXXXXK0OO0KKOdooddoooodddddxxlxNMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMN0kkOKXXXXXXXXXXXxlllooddddddxkkkkkKWMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMWKxoxOKXXXXXXXXXKOxdllllllllloxkKWMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMN0OkxxdxxxkkO0KXKKKK0OkxdollloOXWMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMN0OOKK0OOkkxdddxxxddddddddddxkkkkKNMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMWKkk0KKXXKK00OOOOkkkkkkkkkkkOOOOOOOO0KWMMMMMMMMMMMMMMM
// MMMMMMMMMMN00K000xxOO0KXXXXXXKKK00000000000000000KKNXO0WMMMMMMMMMMMMMM
// MMMMMMMMMMKdoolcldkOKKKKKKXXXXXXKKKKXXXXXXXXXXXXXXKKXXO0WMMMMMMMMMMMMM
// MMMMMMMMMMXxxkoccdkO0KK00KXKKKKOk0KXXXXXXXXXXXXXXXXKO0kONMMMMMMMMMMMMM
// MMMMMMMMMMWOdkkolodxkOOO0Oxkkkxk0XXXXXXXXXXXXXXXXXXX0ddONMMMMMMMMMMMMM
// MMMMMMMMMMMNOxxxxdoooodxxxdxkO0KKKXXXXXXXXXXXXXXXXXKOkKNMMMMMMMMMMMMMM
// MMMMMMMMMMMMWXOxxkOxdxO0KKKXXXXOx0XXXXXXXXXXXXXXXXKO0NMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMWXOkxold0XXXXXXX0ddk0KKXXXXXXXXXXXK00KWMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMWX0xlxOKXXXX0dlooxxkOO0O000OOkO0XWMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMWKkdxOO0OO0K0OOOOOxlllllllxNMMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMWWN0oclookXMMMMMMMMNOlclllo0NNNNWMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMNOxolooloxOOXWMMMMMN0dlcclclxkddkOKWMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMWkccccloc:odlxNMMMMWOlcccc;;cddlcoodKMMMMMMMMMMMMMMMM

// Development help from @lozzereth (www.allthingsweb3.com)

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Bread is Ownable, ERC20 {
    // Maximum supply, starts from 1B then decreasable later in time
    // as staking/rewards/etc are modelled by the team
    uint256 maximumSupply = 1000000000 * 1e18;

    // Authorised minters will often be other contracts
    mapping(address => bool) public authorisedMinters;

    constructor() ERC20("Bread", "BREAD") {}

    /**
     * Adds one or more authorised minting address
     */
    function setAuthorisedMinter(address[] calldata minters)
        external
        onlyOwner
    {
        for (uint256 i; i < minters.length; i++) {
            authorisedMinters[minters[i]] = true;
        }
    }

    /**
     * Allows an address (typically a contract) to mint the token
     */
    function authorisedMint(address account, uint256 amount) external {
        require(authorisedMinters[_msgSender()], "Cannot Issue Token");
        require(totalSupply() + amount <= maximumSupply, "Maximum Supply Hit");
        _mint(account, amount);
    }

    /**
     * Decreases maximum supply, cannot be increased afterwards
     */
    function decreaseMaximumSupply(uint256 _total) external onlyOwner {
        require(_total <= maximumSupply, "Over Max Supply");
        require(_total >= totalSupply(), "Under Total Supply");
        maximumSupply = _total;
    }

    /**
     * Check if we're over the total supply
     */
    function overTotalSupply() external view returns (bool) {
        return totalSupply() >= maximumSupply;
    }
}