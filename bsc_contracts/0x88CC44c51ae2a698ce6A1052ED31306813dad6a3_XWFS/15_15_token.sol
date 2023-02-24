// SPDX-License-Identifier: MIT
/**
 * @title Xave World Forest Land sale token
 * @author Xave Project
 * @notice BEP20 (ERC20) official XWFS token
 * 
 *                          .:^~!7????JJJJJ???77!~^..                         
 *                     .:~7?J??7!~^:::.....:::^~!7????!~:.                    
 *                  :!?JJ7~:.  .:^^~!!!777!!!~^:..  .^~7??7~:                 
 *               :!JJ?~.  :~!?JYYYYYYYYYYYYYYYYYYJ?7!^.  :~?J?~:              
 *            .~?Y?^  .~?JYYYYYYYYYYYYYYYYYYYYYYYYYYYYJ?7^. .~?J?^            
 *          .!YY!. .~?YYYYYYYYYYYYYYYYYYYYYYYYYYYYYYJJJYYYJ7^  :!J?~          
 *         ~YY~  :7Y5YYYYYYYYYYYY?^::7YYYYYYYYYYYYYYYJYJJJJYY~   .!J?^        
 *       :?57. :?Y5YYYYYYJJYYYYYY^   .JYYYYJ77?YYYYYYYYYJJJJY~     :7Y7.      
 *      ~5Y: .755YYYYYYY^. .7YYYY^   .JYYY?.   7YYYYJ7!7JYYJY!    ^  ~JJ^     
 *     !5?. ^Y5YYYYYYYYY^  .7YYYY^   .JYYY?    !YYYY^   ^YYJY!    ??. :JY~    
 *    !57  ~555555YYYYY55J?Y5YYYY^   .JYYY?    !YYYY.   :JYYY!    7YJ: .?Y~   
 *   ~5?  ~5555555YYYY5Y~..:?YYYY^   .JYYY?    !YYYY:   :YYYY!    7YYJ: .JY^  
 *  :5Y. ^5555555555555J    ^5YYY^   .JYYY?    !YYYY:   :YYYY!    7YJY?. ^YJ. 
 *  ?P~  J5555555555555J    ^5YY5^   .JYYY?    !YYYY:   :YYYY!    7YYJY!  7Y! 
 * :5Y. ~55555Y7~!?5555J    ^5YY5^   .JYYY?    !YYYY:   :YYYY!    7YYYYJ: :YJ.
 * ~P7  ?55555!    J555J    ^5YY5^   .JYYY?    !YYYY:   :YYYY!    7YYYYY~  ?Y^
 * 7P!  Y55555~    J555J    ^555Y:   .JYYY?    !YYYY:   :YYYY!    7YYYYY7  7Y~
 * ?P~ .Y55555~    J555J     :~~:    .JYY5?    !YYYY:   :YYYY!    7YYYYY7  7Y!
 * 7P!  Y55555~    J555J     ~77^    .J5Y5?    !5YYY.   :YYYY!    7YYYYY7  7Y~
 * ~P?  ?555557   .Y555J    ^5555^   .J5Y5?    .!?7~    :YYYY!    7YYYYY~ .JY^
 * .55. ^555555J77Y5555J    ^5555^   .J5Y5?     :^^.    :YYYY?.  :JYYYYJ. ^Y?.
 *  7P!  JP55555P555555J    ^5555^    J5Y5?    ~555J.   :YYYYYY??YYYYYY!  7Y~ 
 *  .Y5: :5555555555555J    ^5555~   .Y555J    75YYY:   :YYYYYYYYYYYYY?  ~Y?  
 *   ^PJ. ^5P5555555555J    ^5555Y7!7J55555J!!?YYY5Y:   :YYYYYYYYYYYYJ. :YY:  
 *    ~PJ. ^5P555555555J    ^555555555555555555YYY5Y:   :YYYYYYYYYYYJ. :JY^   
 *     ~PY: :JP55555555J    ^5555?:.:!5555555555555Y:   :YYYYYYYYYY7. ^YY^    
 *      ^Y5~  !5P555555J    ^5555^    Y555555555555Y.   :YYYYYYY5J^  !YJ:     
 *       .?PJ: .75P5555Y    ^5555^    Y5555555555555:   ^YYYYY5Y!  ^JY!       
 *         ^J57. .7YPPPY    ^5555^    Y5555555555555Y7!7Y5555J~  :?Y?:        
 *           ^J5?:  ^?5Y    ^5555J~:^755555555555555555555J7:  ^?Y?:          
 *             ^?5Y!. .:    ^P555555555555555555555555Y?!:  :7YY7:            
 *               .~JYY7^.   :?JY5555P55555555555YY?7~:. .^7JY?^.              
 *                  .^7JYJ7~:.  .:^^~!!!!!!~~^::.  .^~7JYJ!^.                 
 *                      .^!?JJJJ?7!~^^^^^^^^~~!7?JJJJ7!^.                     
 *                           .:^~!7??JJJJJJJ??7!~^:.                         
 * 
 * @dev Version 1
 */

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "@openzeppelin/contracts/utils/Context.sol";

contract XWFS is Context, AccessControlEnumerable, ERC20Burnable {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    constructor(uint256 initialSupply) ERC20("Xave World Forest Sale Token", "XWFS") {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());

        _setupRole(MINTER_ROLE, _msgSender());
        _mint(msg.sender, initialSupply);
    }

    /**
     * @dev Creates `amount` new tokens for `to`.
     *
     * See {ERC20-_mint}.
     *
     * Requirements:
     *
     * - the caller must have the `MINTER_ROLE`.
     */
    function mint(address to, uint256 amount) public virtual {
        require(hasRole(MINTER_ROLE, _msgSender()), "XWFS: must have minter role to mint");
        _mint(to, amount);
    }

    function decimals() public view virtual override returns (uint8) {
        return 5;
    }
    
}