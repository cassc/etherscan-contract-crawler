// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @dao: MEME
/// @author: Wizard

/*
                                                                                
                                        %//%                                    
     .%%%%%%%/                        #%////%                     %%%%(         
         %#((////%%%                 %%//////%              %&(//((%            
           %%(((//////%%#           .%////////%        %&%/////((%#             
              %((((///////#%&       %//////////%    %%//////(((#%               
                %#((((////////%%.  %//////////(%%%%///////((((%%                
                  %#(((((/////////%%(((/////(((%////////(((((%              /%%%
                    %(((((((/////////%(((((((%/////////(((((%      %%%%////(%%  
 %%%%%%%%%%%%%.       %(((((((//////////&(((#////////((((((%. %%%//////((%%     
    %%%(((/////////%%% %%((((((((//////////%////////((((((%%%//////(((%#        
        (%%(((((////////%%(((((((((//////////(%////((((((%//////(((%%           
            %%((((((////////%((((((((///////////%/((((&//////((((%%             
               %%(((((((///////(%((((((///////////&%///////((((%%               
                  %%((((((((///////%#((((////////%//////(((((%%                 
                     %#((((((((////////%(((////%//////((((((%                   
                       %&(((((((((////////&(/%///////(((((%%%%%%%               
                  %%%%%%%%%(((((%%(////%%%%//%/////(((%%#????,%(                
                    %?????,,%#////////%(((((%///%/(%%,????,,,%                  
                    ?%%,,???%%////////%(((((((%//%,,???,,,,,,%///%              
                  %///#%,,,,???%//////%%%%%%%%%%,,????,,,,,,,%//(//             
                      (%,,,,,,??%////%?,,,,,,%%,,???,,,,,,,,,%?                 
                       %%%,,????%//%,,??????,,,,%%?,,,,,,,,,,%%                 
                    %%,,,????,,%%,,,,,,,,,???????,%%%,,,,,,,,%%                 
                  %/?,?????,,,,,,,,,,,,,,????????,,,,,,%%,,,,%                  
                %????/%%%%,,,,,,,,,,,,,,???,,,,,???,,,,,,%,,,%                  
               %#??,% %%%%%??,,,,,,,%?%#%%%,,,,,,,???,,,,,,,,?%                 
               %,,,,,,%%%%,??????,,%% %(%%%,,,,,,,,,????,,,,???%                
              %,,,,,,,%(,,,,,,,,???,???,,,,,,,,,,,,,,,????,???,,%               
              %,,,?%%%%%%,,,,,,,,????,,,,,,,,,,,,,,,,,,,?????,,,%               
             %?,(%%#######%,,?????,????,,,,,,,,,,,,,,,,,??????,,%%              
             %???/%####%%%????,,,,,,,????,,,,,,,,,,,,,????,,???,%%              
            %%,,(??,%?,,???,,,,,,,,,,,,?????,,,,,,,,,???,,,,,???%               
            %%,,,%??(,????,,,,,,,,,,,,,,,,?????,,,,???,,,,,,,???%               
             %,,,,,%%##%%,,,,,,,,,,,#,,,,,,,,,??????,,,,,,,,,,?%%               
              %,,,,,%??,,,,????,,,,,,,,,,,,,,,??????,,,,,,,,,??%                
               %,,,,???,%%%%%%%/?,,,,,,,,,,????,,,,????,,,,,??%                 
                %%???,,,,,,,,,,,????,,,,?????,,,,,,,,???,????%                  
                  %?,,,,,,,,,,,,,,???????,,,,,,,,,,,,,?????,%                   
                    %,,,,,,,,???????????,,,,,,,,,,,,??????%%                    
                      %/??????,,,,,,,,???,,,,,,,,?????,,%%                      
                        %%,,,,,,,,,,,,,???,,,,?????,,%%                         
                           %%%,,,,,,,,,,,???????,%%,                            
                                %%%%%%%%%%%%%(                                                                                                           
*/

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Capped.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./DontBurnMeme.sol";

interface OriginalMemeToken {
    function balanceOf(address account) external view returns (uint256);

    function burnFrom(address account, uint256 amount) external;
}

contract MEME is ERC20, ERC20Capped, ReentrancyGuard, Ownable {
    OriginalMemeToken public meme;
    DontBurnMeme public burntoken;

    uint256 public constant DENOMINATOR = 10000;
    uint256 public constant MULTIPLYER = 15;
    uint256 public dontBurn = 35555 * (10**uint256(18));
    uint256 internal _mustSwap = 5 * (10**uint256(8));
    bool public treasuryMinted;
    address public memeTreasury;
    uint256 public burnToTreasury = 300;
    bool public allowSwap = false;

    event Swap(address sender, uint256 amount, uint256 received);

    constructor(address _memeAddress, address _treasury)
        ERC20("MEME Inu.", "MEME")
        ERC20Capped(30800 * (10**uint256(23)))
    {
        meme = OriginalMemeToken(_memeAddress);
        memeTreasury = _treasury;
    }

    function setAllowSwap(bool allow) public virtual onlyOwner {
        allowSwap = allow;
    }

    function setMemeTreasury(address treasury) public virtual onlyOwner {
        memeTreasury = treasury;
    }

    function setBurnToTreasury(uint256 _amount) public virtual onlyOwner {
        burnToTreasury = _amount;
    }

    function setBurnToken(address _burntoken) public virtual onlyOwner {
        burntoken = DontBurnMeme(_burntoken);
    }

    function setDontBurn(uint256 amount) public virtual onlyOwner {
        dontBurn = amount;
    }

    function setMustBurn(uint256 amount) public virtual onlyOwner {
        dontBurn = amount;
    }

    function mintTreasuryAmount() public virtual onlyOwner {
        require(treasuryMinted == false, "cannot mint more");
        treasuryMinted = true;
        _mint(memeTreasury, 280000000 * (10**uint256(18)));
    }

    function mintAmount(uint256 amount)
        public
        view
        virtual
        returns (uint256 swapAmount)
    {
        return amount * (10**uint256(MULTIPLYER));
    }

    function swapMax() public virtual nonReentrant returns (uint256 received) {
        uint256 amount = meme.balanceOf(_msgSender());
        return swap(amount);
    }

    function swap(uint256 amount)
        public
        virtual
        nonReentrant
        returns (uint256 received)
    {
        require(allowSwap == true, "meme inu says wait");
        require(_msgSender() != address(0), "swap from the zero address");
        require(
            meme.balanceOf(_msgSender()) >= amount,
            "swap amount exceeds balance"
        );

        uint256 balance = meme.balanceOf(_msgSender());
        uint256 amountToBurn = amount;
        uint256 amountToMint = mintAmount(amount);
        meme.burnFrom(_msgSender(), amountToBurn);

        // check the balance after burn
        require(
            meme.balanceOf(_msgSender()) == (balance - amount),
            "burn failed"
        );

        _mint(_msgSender(), amountToMint);
        _afterSwap(_msgSender(), amount);

        emit Swap(_msgSender(), amount, amountToMint);
        return amountToMint;
    }

    function burn(uint256 amount) public virtual {
        uint256 treasuryBurn = (amount * burnToTreasury) / DENOMINATOR;
        _transfer(_msgSender(), memeTreasury, treasuryBurn);
        _burn(_msgSender(), amount - treasuryBurn);
        _afterBurn(_msgSender(), amount);
    }

    function burnFrom(address account, uint256 amount) public virtual {
        uint256 currentAllowance = allowance(account, _msgSender());
        require(currentAllowance >= amount, "burn amount exceeds allowance");
        unchecked {
            _approve(account, _msgSender(), currentAllowance - amount);
        }
        _burn(account, amount);
        _afterBurn(account, amount);
    }

    function _afterBurn(address account, uint256 amount) internal virtual {
        if (amount >= dontBurn) {
            burntoken.mint(account, 2, 1, "");
        }
    }

    function _afterSwap(address account, uint256 amount) internal virtual {
        if (amount >= _mustSwap) {
            burntoken.mint(account, 1, 1, "");
        }
    }

    function _mint(address account, uint256 amount)
        internal
        virtual
        override(ERC20, ERC20Capped)
    {
        require(ERC20.totalSupply() + amount <= cap(), "cap exceeded");
        super._mint(account, amount);
    }
}