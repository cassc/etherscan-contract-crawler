// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "solmate/tokens/ERC20.sol";
import "solmate/auth/Owned.sol";
import "openzeppelin-contracts/utils/structs/EnumerableMap.sol";

/* Popepe Token
 * All memes are created equal
 * Telegram: https://t.me/popepe777
 * Twitter: https://twitter.com/popepe777
 */
/*
                            :                   ::   -==+==  ==++==  ===*    :.           
                           :.                 .:     -+++=+.=+=.:==+:===*     ::          
                          -.               .::.      :+===*=++:  :+=++==*      .:         
                         :.               ::         .+=+==+:-*:.+- .===+.       -.       
                        .:              ::            *==++  .-..-: .=+=+:        :.      
                        -             ::              *=+==+-=+..-+++=*==-         ::     
                       .:           .:                +=+=++=+:. .==+-+==-          :.    
                       :          .::                 +=+=+::=+=-+==. ====           :    
                       :         ::                   =====-  :=+==   ====           :    
                       :        :.                    ======  :+==+.  ====           :    
                      :.      .-                      -+=+=+  *=++==  -==+           :    
                      :      ::                       -+===* .+====+-:-==+           ..   
                      =     :.                        :+===*==+::::=+=++=*           .:   
                      -    .:                         :+=+===--    :-=+==*           ..   
                     ::   -.                          .+=+=+: .:. .-  -+=*.          :    
                     -.  -.                           .+===-::..=--..::+=+.          :    
                     -  -                              +==+.  .=+=+:.  :=+:         .:    
                     : :                               +===-.:::+=+::: :=+:         -     
                     :.:                               +=+=+=  :: .:  :+==-        .-     
                     -=                                ==++=+-::   :: =====        -.     
                     -.                                -+=+==++:.  :=+=+===       .=      
                     .-                                -+++=+=======+-.-===     .-+:      
                      :.                               :+===+. :+=+=*  -===  .:=+=+       
                       :                               :++===: .+===+  :+++-=+====-       
                       :-::::......                    :+====:  .++*=--=++=====+=*        
                       .+====+++=++++++++++++===========++++++++++=====+==+==#==+=        
                        =++++++=====+++=========+++=====+=+=======++==+--:. =+==*.        
                         -...:::-=*+==+=+-:::-++===+++++++=====*++:.-+==:  -+===+         
                         .: ....:+==+-.  -. .-  :=+==:       :+++=:.-+==+==+===*:         
                          -+=++++==-...:::+-+:::...==+++=--:=+-..-:.-.  -++++==*          
                           ===+++=+:   ..=+=+-..   -=======+==-..=-.=+-=+-..+=+-          
                           .:....====:.. .:.-. .::===+===-:..==++=  .===:.-===+           
                            ====-=+===-.::   -.:-+=+=         :=++=-+=*==+===+.           
.                          .=====++++===+=====+==+*=-----------=++=+==+==+=++.            
                          -***++++==+==+==+==================+=+=+=++===+**:              
                        :**++++++***+++++++==========++===+=+====++++****+*+.             
                       -*++++*++++********######*******#**********++++*******-            
                      =*++++++****+*******************++**#++++++++**********#*+-.        
                     +*++*++*#*+****+++++++++++**********+*#*+++++****+**********#=       
                    =*++++++*++*#+++++++++++++++++++*#*+**++#*++*#***#**++*+++*#*#.       
                   -*++++++****#**=----=%#+%%%%%%%=::::-+***+*+++*=*#%@%%*===+***#        
                  .*+++++++++++++**+=..#@#[email protected]@%-:*@#     .***#*++*.**[email protected]%*+#.  .:=+        
                  =++*++++++++++++**+**#%%+%@%=-*@@.      +****=. @@*#@*. +=    :*        
                 .*++*+++++++*+++++**+++++*#%%@@@@=       :#*+*=-.#@%@@@@@@:.-=+*=        
                 =*+*++++++++++++++*+*******+++***++===+++*****+*************+**=         
                =#++++++**++*+++*+*+++++++**************#****+***##*****++****#=          
               -*#+**+++++++***++++++++++++++***++++++*#*+*+++++*+****+++*******=         
              .*+#+++++++++**+++*++++++++++++*+++++****+++*+++++++++****+++++*++*=        
              =++*++*+***+******+++++++++++++++*****++++++++++++++*++++*+++++++++#*=.     
              *++*++++++*****#*#**+++++++++++***++++++++++++++++++++++++++++++++*#*#=     
             -*++*++++++++##*###*###***+++++++++++++++++++++++++++++++++++++++**#**+.     
            :+*++++++++*++*##*###%#***######****+++++++++++++++++++++++++++++**#**=       
          .:. =*+++++========+++*++**+++*++++++*#####***********************#####:        
         .:    =*+++=+*= :+++++**###****#######+######**#*******#######*****##%#*=        
        .:      :+*+=**- .+*****+***#####*##***+###############################**-        
        -         :++*=: :=++++++++++++*****++-=*#########################*#*##*-         
       .:           -*-:-=**+:..::----------::.+*##########################***#.          
      :. ...        =*##*++**=   .:----:...  .+*+++++********************+++++*.          
     .      ...    -#**++***+::-=+***##:.   -#*++++++++++++++++++++++++++++***-           
    .          ...:#++*+*%#******++****-:--**++*++++++++++++++++++++++++++++*+:..         
    .            :#+*++***++****+##**++***#*++++++++++++++++++++++++++++++++:    ::       
    .          =:+#+++++**+*+*######*+++**#++***+++++++++++++++***++++++**- .      ...    
   .          .*:**++++++++*####**+++**#*-.....:::::::=+=:::=++-:::::::::.. .         .   
  ..            -#+++++++++**+*++++******=.           :      .           ....          .. 
  .           :+#++++++++++++*******++++*=            :      .             -             .
 .            :@*+*++++++++++++**++++*#+..        ...:*... ..:.        ...:.              
.             --=*+*++++++++++*+++**=-. .......: :    +=..   :.  ..::..   :               
              -: =+*+*+++++++++*#%-.      . ...  ..    *:.    - ...       :               
               +- :+*+++++++++++#:          -..   ..  .==   ..            .               
                -=. :=+*+*+++****           :  ..   . :++. :.            :                
                  -*-. .:=#+=:..            :    .:--=++=---:.           :                
                   -:::...                  :      -==***==--            :                
*/
contract Popepe is ERC20, Owned {
    using EnumerableMap for EnumerableMap.AddressToUintMap;
    EnumerableMap.AddressToUintMap internal sacrifices;

    uint256 public maxWallet;
    mapping(address => bool) public isExcludedFromMaxWallet;
    

    event ExcludedFromMaxWallet(address indexed wallet, bool isExcluded);
    event UpdateMaxWallet(uint256 newMaxWallet, uint256 oldMaxWallet);
    event TokenSacrifice(address indexed wallet, uint256 amount);

    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals,
        uint256 _totalSupply,
        uint256 _maxWallet,
        address _owner
    ) ERC20(_name, _symbol, _decimals) Owned(_owner) payable {
        maxWallet = _maxWallet;
        isExcludedFromMaxWallet[address(this)] = true;
        isExcludedFromMaxWallet[address(0xdead)] = true;
        isExcludedFromMaxWallet[address(0)] = true;
        isExcludedFromMaxWallet[msg.sender] = true;
        isExcludedFromMaxWallet[_owner] = true;
        emit ExcludedFromMaxWallet(address(this), true);
        emit ExcludedFromMaxWallet(address(0xdead), true);
        emit ExcludedFromMaxWallet(address(0), true);
        emit ExcludedFromMaxWallet(msg.sender, true);
        emit ExcludedFromMaxWallet(_owner, true);
        _mint(_owner, _totalSupply);
    }

    function updateMaxWallet(uint256 _maxWallet) public onlyOwner {
        require(_maxWallet >= 777777777000000000000, "Popepe: maxWallet !< 777777777000000000000");
        emit UpdateMaxWallet(_maxWallet, maxWallet);
        maxWallet = _maxWallet;
    }

    function excludeFromMaxWallet(address _wallet, bool _status) public onlyOwner {
        require(isExcludedFromMaxWallet[_wallet] != _status, "Popepe: wallet status unchanged");
        isExcludedFromMaxWallet[_wallet] = _status;
        emit ExcludedFromMaxWallet(_wallet, _status);
    }

    function excludeFromMaxWalletBatch(address[] memory _wallets, bool _status) public onlyOwner {
        for (uint i; i < _wallets.length;) {
            isExcludedFromMaxWallet[_wallets[i]] = _status;
            unchecked { ++i; }
        }
    }

    function transfer(address _to, uint256 _amount) public override returns (bool) {
        if (!isExcludedFromMaxWallet[_to]) {
            require(_amount <= maxWallet, "Popepe: TX amount > max wallet limit");
            require((balanceOf[_to] + _amount) <= maxWallet, 
                "Popepe: Recipient balance would exceed max wallet limit");
        }
        return super.transfer(_to, _amount);
    }

    function transferFrom(
        address _from,
        address _to,
        uint256 _amount
    ) public override returns (bool) {
        if (!isExcludedFromMaxWallet[_to]) {
            require(_amount <= maxWallet, "Popepe: TX amount > max wallet limit");
            require((balanceOf[_to] + _amount) <= maxWallet, 
                "Popepe: Recipient balance would exceed max wallet limit");
        }
        return super.transferFrom(_from, _to, _amount);
    }

    function sacrifice(uint256 _amount) public returns (bool) {
        require(balanceOf[msg.sender] >= _amount, "Popepe: sacrifice > balance");
        _burn(msg.sender, _amount);
        uint256 totalBurned;
        if (EnumerableMap.contains(sacrifices, msg.sender)) {
            totalBurned += EnumerableMap.get(sacrifices, msg.sender);
        }
        totalBurned += _amount;
        EnumerableMap.set(sacrifices, msg.sender, totalBurned);
        emit TokenSacrifice(msg.sender, _amount);
        return true;
    }

    function listSacrificers() public view returns (address[] memory) {
        return EnumerableMap.keys(sacrifices);
    }

    function getSacrifice(address _wallet) public view returns (uint256) {
        return EnumerableMap.get(sacrifices, _wallet);
    }
}