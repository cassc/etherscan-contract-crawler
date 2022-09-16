// SPDX-License-Identifier: MIT License
// 
//                                                        [email protected],              
//                                                @@@@@@@@@@@@@@@@@@@      
//                                            @@@@@@@@@@@@@@@@@@@@@@@@@@   
//                                        [email protected]@@@@@@@                @@@@@@  
//                                      @@@@@@@@                     @@@@@(
//                                   @@@@@@@&                         @@@@@
//        @@@@@@@@@@@@@@          @@@@@@@@                            @@@@@
//     &@@@@@@@@@@@@@@@@@@@@   @@@@@@@@                               @@@@@
//    @@@@@@          @@@@@@@@@@@@@@                                  @@@@@
//    @@@@@               @@@@@@@@                                   @@@@@@
//    @@@@@            @@@@@@@@@@@@@@                               @@@@@@ 
//     @@@@@@*     *@@@@@@@@    @@@@@@@@                           @@@@@@  
//      @@@@@@@@@@@@@@@@@          @@@@@@@@@                    @@@@@@@    
//          @@@@@@@@@                 &@@@@@@@@@@           @@@@@@@@@      
//                                        @@@@@@@@@@@@@@@@@@@@@@@@         
//                                             @@@@@@@@@@@@@@              
// 
//
//             .d88888b.  888888b.    .d88888b.  888      
//            d88P" "Y88b 888  "88b  d88P" "Y88b 888      
//            888     888 888  .88P  888     888 888      
//            888     888 8888888K.  888     888 888      
//            888     888 888  "Y88b 888     888 888      
//            888     888 888    888 888     888 888      
//            Y88b. .d88P 888   d88P Y88b. .d88P 888      
//             "Y88888P"  8888888P"   "Y88888P"  88888888 



pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/draft-ERC20Permit.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Votes.sol";
import "./lib/IENSReverseRegistrar.sol";


contract ObolToken is ERC20, AccessControl, ERC20Permit, ERC20Votes {

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    constructor(address _admin, address _minter, address _ensReverseRegistrar, address _ensOwner) ERC20("Obol Network", "OBOL") ERC20Permit("Obol Network") {
        _grantRole(DEFAULT_ADMIN_ROLE, _admin);
        _grantRole(MINTER_ROLE, _minter);
        IENSReverseRegistrar(_ensReverseRegistrar).setName("obol.eth");
        IENSReverseRegistrar(_ensReverseRegistrar).claim(_ensOwner);
    }

    /**
     * @notice Mints token to address.
     * @param _to Receives minted tokens.
     * @param _amount Amount of tokens to mint.
     */
    function mint(address _to, uint256 _amount) public onlyRole(MINTER_ROLE) {
        _mint(_to, _amount);
    }

    /**
     * @notice Burns sender's tokens.
     * @param _amount Amount of tokens to burn.
     */
    function burn(uint256 _amount) public {
        _burn(msg.sender, _amount);
    }

    /**
     * @notice Burns tokens on behalf of an account. Similar to transferFrom, sender must have an allowance from account.
     * @param _owner Address whose tokens will be burned.
     * @param _amount Amount of tokens to burn.
     */
    function burnFrom(address _owner, uint256 _amount) public {
        _spendAllowance(_owner, msg.sender, _amount);
        _burn(_owner, _amount);
    }

    /**
     * @inheritdoc ERC20
     * @dev Added requirement that _to address cannot be the ObolToken address.
     */
    function _beforeTokenTransfer(address /* from */, address _to, uint256 /* _amount */) internal view override {
        require(_to != address(this), "No transfer to ObolToken.");
    }

    // The following functions are overrides required by Solidity.

    function _afterTokenTransfer(address _from, address _to, uint256 _amount)
        internal
        override(ERC20, ERC20Votes)
    {
        super._afterTokenTransfer(_from, _to, _amount);
    }

    function _mint(address _to, uint256 _amount)
        internal
        override(ERC20, ERC20Votes)
    {
        super._mint(_to, _amount);
    }

    function _burn(address _account, uint256 _amount)
        internal
        override(ERC20, ERC20Votes)
    {
        super._burn(_account, _amount);
    }
}