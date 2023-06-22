// SPDX-License-Identifier: MIT
/*
   .-'''-. .--.      .--.    .-''-.      .-''-. ,---------.         ,---------.    ,-----.    .--.   .--.      .-''-.  ,---.   .--. 
  / _     \|  |_     |  |  .'_ _   \   .'_ _   \\          \        \          \ .'  .-,  '.  |  | _/  /     .'_ _   \ |    \  |  | 
 (`' )/`--'| _( )_   |  | / ( ` )   ' / ( ` )   '`--.  ,---'         `--.  ,---'/ ,-.|  \ _ \ | (`' ) /     / ( ` )   '|  ,  \ |  | 
(_ o _).   |(_ o _)  |  |. (_ o _)  |. (_ o _)  |   |   \               |   \  ;  \  '_ /  | :|(_ ()_)     . (_ o _)  ||  |\_ \|  | 
 (_,_). '. | (_,_) \ |  ||  (_,_)___||  (_,_)___|   :_ _:               :_ _:  |  _`,/ \ _/  || (_,_)   __ |  (_,_)___||  _( )_\  | 
.---.  \  :|  |/    \|  |'  \   .---.'  \   .---.   (_I_)               (_I_)  : (  '\_/ \   ;|  |\ \  |  |'  \   .---.| (_ o _)  | 
\    `-'  ||  '  /\  `  | \  `-'    / \  `-'    /  (_(=)_)             (_(=)_)  \ `"/  \  ) / |  | \ `'   / \  `-'    /|  (_,_)\  | 
 \       / |    /  \    |  \       /   \       /    (_I_)               (_I_)    '. \_/``".'  |  |  \    /   \       / |  |    |  | 
  `-...-'  `---'    `---`   `'-..-'     `'-..-'     '---'               '---'      '-----'    `--'   `'-'     `'-..-'  '--'    '--' 
                                                                                                                                    
        TG: https://t.me/sweet_coin
        Website: https://Sweet.ooo 
        Twitter: https://twitter.com/sweetcryptocoin






*/
pragma solidity ^0.8.9;

import "@openzeppelin/[email protected]/token/ERC20/ERC20.sol";
import "@openzeppelin/[email protected]/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/[email protected]/access/Ownable.sol";

contract Sweet is ERC20, ERC20Burnable, Ownable {
    constructor() ERC20("Sweet", "SWEET") {
        _mint(msg.sender, 1000000 * 10 ** decimals());
    }
}