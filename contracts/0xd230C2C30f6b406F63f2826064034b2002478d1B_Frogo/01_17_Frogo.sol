// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * FROGO, The Fellowship of PEPE. Frogo is our only hope of uniting the PEPE community around a single goal: to restore peace to Middle Pepearth and bring back PEPE as the only ring.
 *
 *
 *                           . .:.:.:.:. .:\     /:. .:.:.:.:. ,
 *                      .-._  `..:.:. . .:.:`- -':.:. . .:.:.,'  _.-.
 *                     .:.:.`-._`-._..-''_...---..._``-.._.-'_.-'.:.:.
 *                  .:.:. . .:_.`' _..-''._________,``-.._ `.._:. . .:.:.
 *               .:.:. . . ,-'_.-''      ||_-(O)-_||      ``-._`-. . . .:.:.
 *              .:. . . .,'_.'           '---------'           `._`.. . . .:.
 *            :.:. . . ,','               _________               `.`. . . .:.:
 *           `.:.:. .,','            _.-''_________``-._            `._.     _.'
 *         -._  `._./ /            ,'_.-'' ,       ``-._`.          ,' '`:..'  _.-
 *        .:.:`-.._' /           ,','                   `.`.       /'  '  \\.-':.:.
 *        :.:. . ./ /          ,','               ,       `.`.    / '  '  '\\. .:.:
 *       :.:. . ./ /          / /    ,                      \ \  :  '  '  ' \\. .:.:
 *       .:. . ./ /          / /            ,          ,     \ \ :  '  '  ' '::. .:.
 *       :. . .: :    o     / /                               \ ;'  '  '  ' ':: . .:
 *       .:. . | |   /_\   : :     ,                      ,    : '  '  '  ' ' :: .:.
 *       :. . .| |  ((<))  | |,          ,       ,             |\'__',-._.' ' ||. .:
 *       .:.:. | |   `-'   | |---....____                      | ,---\/--/  ' ||:.:.
 *       ------| |         : :    ,.     ```--..._   ,         |''  '  '  ' ' ||----
 *       _...--. |  ,       \ \             ,.    `-._     ,  /: '  '  '  ' ' ;;..._
 *       :.:. .| | -O-       \ \    ,.                `._    / /:'  '  '  ' ':: .:.:
 *       .:. . | |_(`__       \ \                        `. / / :'  '  '  ' ';;. .:.
 *       :. . .<' (_)  `>      `.`.          ,.    ,.     ,','   \  '  '  ' ;;. . .:
 *       .:. . |):-.--'(         `.`-._  ,.           _,-','      \ '  '  '//| . .:.
 *       :. . .;)()(__)(___________`-._`-.._______..-'_.-'_________\'  '  //_:. . .:
 *       .:.:,' \/\/--\/--------------------------------------------`._',;'`. `.:.:.
 *       :.,' ,' ,'  ,'  /   /   /   ,-------------------.   \   \   \  `. `.`. `..:
 *       ,' ,'  '   /   /   /   /   //                   \\   \   \   \   \  ` `....
 *
 * Join the movement: https://t.me/FrogoToken
 * Follow us: https://twitter.com/FrogoToken
 * Learn more: https://frogo.io
 */
contract Frogo is ERC20, ERC20Permit, Ownable {
    uint256 public constant SUPPLY = 420690000000000 ether;
    uint256 public maxShareByWallet; 
    bool public isSwapEnabled = false;
    mapping(address => bool) public isExcludedFromRestrictions; // Exclude uniswap contracts from maxShareByWallet
    address public pool;

    error SwapIsNotEnabled();
    error MaxShareByWalletReached();
    constructor() ERC20("Frogo", "FROGO") ERC20Permit("Frogo") {
        _mint(msg.sender, SUPPLY);
        maxShareByWallet = SUPPLY * 10 / 1000; // 1%
        isExcludedFromRestrictions[msg.sender] = true;
        isExcludedFromRestrictions[address(0xC36442b4a4522E871399CD717aBDD847Ab11FE88)] = true; // Exclude Uniswap v3 NonfungiblePositionManager
        isExcludedFromRestrictions[address(0x1F98431c8aD98523631AE4a59f267346ea31F984)] = true; // Exclude Uniswap v3 PoolFactory
    }

    function _transfer(address from, address to, uint256 amount) internal override(ERC20)  {
        if (!isSwapEnabled && from != owner() && to != owner()) {
            revert SwapIsNotEnabled(); 
        }

        if(from != owner() && !isExcludedFromRestrictions[to] && super.balanceOf(to) + amount > maxShareByWallet){
            revert MaxShareByWalletReached(); 
        }

        super._transfer(from, to, amount);  
    }

    /**
     * Allow to exclude the owner and uniswap v3 contracts from maxShare restriction to allow us at the very begining to create the pool and lock the tokens. We will rennonce few minutes after launch.
     */
    function excludeFromMaxRestrictions(
        address _address,
        bool _isExclude
    ) public onlyOwner {
        isExcludedFromRestrictions[_address] = _isExclude;
    }

    /**
     * As soon as the pool is created, we will set it in the contract and exclude it for trading & maxShare restriction to prevent bug
     */
    function setPool(address _address) external onlyOwner {
        pool = _address;
        isExcludedFromRestrictions[_address] = true;
    }

    /**
     * 1% during launch, then can be update to 2%
     */
    function setMaxShareByWallet(uint256 _newShare) external onlyOwner {
        maxShareByWallet = _newShare;
    }

    /**
     * This will be called once at the very begining after liquidity added on uniswapv3. isSwapEnabled can never be put back to false
     */
    function enableSwap() external onlyOwner {
        isSwapEnabled = true;
    }
}