/*
    Copyright 2020, 2021 Empty Set Squad <[email protected]>

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
*/

pragma solidity 0.5.17;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/ownership/Ownable.sol";
import "./Permittable.sol";
import "../Interfaces.sol";

/**
 * @title Dollar
 * @notice ESD stablecoin ERC20 token
 * @dev Owned by the reserve, which is solely allowed to mint ESD to itself and to burn its held ESD
 */
contract Dollar is IManagedToken, Ownable, Permittable {

    /**
     * @notice Constructs the Dollar contract
     */
    constructor()
    ERC20Detailed("Digital Standard Unit", "DSU", 18)
    Permittable()
    public
    { }

    // ADMIN

    /**
     * @notice Mints `amount` ESD tokens to the {owner}
     * @dev Owner only
     * @param amount Amount of ESD to mint
     */
    function mint(uint256 amount) public onlyOwner {
        _mint(owner(), amount);
    }

    /**
     * @notice Burns `amount` ESD tokens from the {owner}
     * @dev Owner only
     * @param amount Amount of ESD to burn
     */
    function burn(uint256 amount) public onlyOwner {
        _burn(owner(), amount);
    }

    // INFINITE APPROVAL

    /**
     * @notice Transfer `amount` ESD from the `sender` to the `recipient`
     * @dev Extended to support infinite approval
     * @param sender Account to send ESD from
     * @param sender Account to receive the sent ESD
     * @param amount Amount of ESD to transfer
     */
    function transferFrom(address sender, address recipient, uint256 amount) public returns (bool) {
        _transfer(sender, recipient, amount);
        if (allowance(sender, _msgSender()) != uint256(-1)) {
            _approve(
                sender,
                _msgSender(),
                allowance(sender, _msgSender()).sub(amount, "Dollar: transfer amount exceeds allowance"));
        }
        return true;
    }
}