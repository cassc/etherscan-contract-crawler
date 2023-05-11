// SPDX-License-Identifier: The Unlicense

pragma solidity 0.8.17;

import "Owned.sol";

/* 

            _|                                                        
  _|_|_|  _|_|_|_|  _|  _|_|    _|_|_|  _|_|_|      _|_|_|    _|_|    
_|_|        _|      _|_|      _|    _|  _|    _|  _|    _|  _|_|_|_|  
    _|_|    _|      _|        _|    _|  _|    _|  _|    _|  _|        
_|_|_|        _|_|  _|          _|_|_|  _|    _|    _|_|_|    _|_|_|  
                                                        _|            
                                                    _|_|              
                                                                                        
            _|      _|                                      _|                          
  _|_|_|  _|_|_|_|_|_|_|_|  _|  _|_|    _|_|_|    _|_|_|  _|_|_|_|    _|_|    _|  _|_|  
_|    _|    _|      _|      _|_|      _|    _|  _|          _|      _|    _|  _|_|      
_|    _|    _|      _|      _|        _|    _|  _|          _|      _|    _|  _|        
  _|_|_|      _|_|    _|_|  _|          _|_|_|    _|_|_|      _|_|    _|_|    _|        
                                                                                       

MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWNXNWM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWNXXKKWM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWNXXNNKXWM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWNXNWWXKWMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWNXNWMMNKNMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWNXKXKXWWXXWMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWNXKXNNKKNXXWMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWXK00KNNKXNKNMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWXKOkOkkKXXNXXWMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWXKOdodkkk0KNXXWMMMMMM
MMMMMMMMWWWWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWNKOxooxxook0XXXNMMMMMMM
MMMMMMWNXXXXXNNWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWNKOdc::cloldOXNXXWMMMMMMM
MMMMMMNKNWNKKKKXXNWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWNX0xoc:oxl;:lxKNXXWMMMMMMMM
MMMMMMXKN0xdolldxOKXNWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWNX0xl;;:cod:,:d0XXKNMMMMMMMMM
MMMMMMXKKdcllolc::cokKXNWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWXK0xl;,';:;;;,,lkXNKXWMMMMMMMMM
MMMMMMNK0o;cx0KKOxoc:cokKNWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWNNX0xc,''';cc,''':xKNXXWMMMMMMMMMM
MMMMMMWX0d;ckXX0Okkxxoc:cdOKNWWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWNXK0kl;'',cxOo,''';d0NXXNMMMMMMMMMMM
MMMMMMMNKx::kKkxkxoooddoolclx0XNWWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWNXKKko;'',cx0K0o'.',lOXNKXWMMMMMMMMMMM
MMMMMMMWXOl;dOkxolxkxdollodollok0XNWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWNXKKOo:,',cx0K0Od;'''ckKNXXWMMMMMMMMMMMM
MMMMMMMMNKd;cxdlcd00OkxdlcclodoccokKNWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWNXXXKOdc'.':x0XWNOd:'.':xKNXXWMMMMMMMMMMMMM
MMMMMMMMWXk:;odccdkxxxddddolccodoc:lx0XNWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWNXXXKOdc;'';o0NWMWKx:'.';d0NXKNMMMMMMMMMMMMMM
MMMMMMMMMNKo,:olcddox00OkxddolcloddlccoOKNNWMMMMMMMMMMMMMMMMMMMMMMMMMMMWNXXXXKOd:,'';lONWMWWNkc'.',lOXNXNWMMMMMMMMMMMMMM
MMMMMMMMMMNOc,ll:lolxOOOkxdddolllooddoc:lk0XNWMMMMMMMMMMMMMMMMMMMMMMWNNXXXXKOdc;,',ckXWMMMWN0l'.',lkXNXXWMMMMMMMMMMMMMMM
MMMMMMMMMMWKx::occlcoxxxkkxddoooloolloddl:cxOKXNWMMMMMMMMMMMMMMMMWWNXNNNNX0xl:,'':xKWMMWWMWKo,.',ckKNXXWMMMMMMMMMMMMMMMM
MMMMMMMMMMMN0o,cl:ccloodk00kxddoodooollodxoccokKXNWWWMMMMMMMMMWWNXXNNNXKOdc:;'';o0NWMMMMMWXd;.',cxKNNKNMMMMMMMMMMMMMMMMM
MMMMMMMMMMMWXOc,clcccllldkOkxddoooooooooooxkdc:lk0XXNWMMMMMWWNXXNWWNXX0xl;;,',ckXWMMMMMMWXx:.',:d0NNKXWMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMWXx;;lc::cl:codxxdllooooooooolloxkxl:cxKXXNWWNXXNNNWWNXK0xoc;;'':d0NWMMMMMMWXkc'.,:dOXNXXWMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMWKd,:c;;:cc:clllll::clooloddoolclxOkl:lx0KKKKNWWWWNXXKkoc:;,',cxKWWMMMMMMWXk:'',;oOXWXKNMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMN0l,:c;:::::c:,;okxo::loolodooolcok0xlcld0XXNNNNXNXOxolc:,';lkXWMMMMMMMWXkl,',;lkKWNKNWMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMWXk:,c::::::c:,'lKWNOc,:loloddooolldkOxlcoOXXK0KK0kxdlcc,,cdOXWMMMMMMMWXkl,.';lkKNWXXWMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMWWXx:;c::c::cc;',dNMWKl,;coooddooollok0OdccoOKX0xddoccc,,cxOXWMMMMMMMWXkl'.';cx0NWXXWMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMNKd;;c:::::::;',xNWWXo,;coooodooxdloxOOxc:coodxdlcc:,,lxOKWMMMMMMWNKkc'.';cx0XWNXNMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMWN0o,:c::::ccc:,;oKWWKc,:lolloddoxdllox0Ol,;::llcc:,;lkOKWMMMMMMWN0xc'.',:d0XWNKNWMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMWNOc,:c;:cccccc:;cx00l,;codoodxdodocldkOoc,,,,;cc,,ck00NWMMMMMWX0xc'',;cdOXWNKXWMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMWXkc,cc::cccclllcclollcloddoodxoloololodl::,',;;::okOKNMMMWWXK0xc'',,:dOXWWXXWMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMWXk:;lc:::clloodooodxddddxdodxdlokoccclol:,','';lk0OOXNNXXXKOd:,,,,;oOKNWXKNMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMWKkc;ll::clooodxxxxxkkkkkxoddxddxdc::cdc;::'.';l0KKK0KKKK0ko:;;,,:d0KNWNKNWMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMWKx:;ol::clodddxkkOO000Oxodxkkdlol::c::clo,.,;ck0KNNXK0xoc:::,,cd0KNWWXXWMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMNKx:;oocclldxxxxkkO000Oxdkkkkocdo:cc,cxxo;,,;cdkkO0kxdlcccc;;cx0KNWWXXWMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMNKk:;odlclooxkkxxkkkOOkkOOkdcldoccc,lxxo;;:::oxkkxdolcclc::cd0KNWWXKNMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMNKx:;odlcodddxkkkkO00000Oxoclooc;::ldddc:ooccloooc:cooc:lld0KNWMNXNMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMWNKx:;oxlclxxddkO000KKK0xddlcldl;::lddol:oOkxollooddoccodkKKNWMNXNWMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMNKkc;okdlldkxddxxkOOOOkOdcoxko;:oolllolcxKK0Okkxooooox0XXNWMWXXWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMNKOl;lkkdoodkOkxxxkO00klldkOl,lxxddooxoldkkkdooodxdx0XXNWMWXKWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMNKOo;:xOxooodxO000K0xloxxO0c;dkkkkxxkOOxdddddxxxkOKXXNWMWXKNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMWNX0x:;dOOkxdodxxxddxOkk0Kx;:xO0KOkkxO0OOO0OxxkOKXXXNWMMNKNWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWXKOl;ck00kxxkkkkOOkOKX0o,ck0XNKkO0OOkkOO0OO0XNXXWWMMNXXWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWNX0d::dOKK0OkkkO0KNNKx;,o00KXXOOKXKKK00O0XWNXNWMMMWXXWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWNXXOoccoOKXXXXNNXXKkc;lkKKKKNWK0O00000XWWNXNWMMMWXKWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWXXXOoccodkO0K00kdoclkKKXK0XWWWXKXNWWWNXNWMMMMWXKNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWNXXKOdlcllolooooddOXXXWX0KWMMMMMMWNXXWMMMMMMNKNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWNXXX0OxdooodxkOKNXKNMNXXXWMWWNNNNNWMMMMMMWXXWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWNXXNNXK0O0KXWWNXNWMWWWNXXXXXNWMMMMMMMMWXXWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWNXXNNWWWWWNXXNWMMMMMWWWWWMMMMMMMMMMMNKNWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWNXXXNXXNNWMMMMMMMMMMMMMMMMMMMMMMWXXWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWMMMMMMMMMMMMMMMMMMMMMMMMMMNKNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNKNWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWXXWWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWNNXNNNWWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWNNXXNWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM

---


Strange Attractor is an experimental token launch mechanism. 

The code has been adapted from Canto Inu's Dog Pound (https://github.com/CantoInu/CantoInu/blob/main/src/DogPound.sol),
keeping only the ETH collection and removing the fixed price and the token distribution. New token launches can use
Strange Attractor to collect ETH and then distribute tokens in proportion to how much ETH each address contributed. 

The basic idea is that there should be some kind of sane middle ground between a token supplying its own initial 
liquidity (which is usually small and leads to a horrible token distribution immediately after launch) and more 
complicated mechanisms like a Liquidity Bootstrap Pool (https://whatincrypto.com/concept/what-is-liquidity-bootstrapping-pool-lbp/) 

The simplest thing is to let the set of early buyers collectively determine the initial AMM price. 

Every new token should use a distributor contractor which pairs 50% of the token supply  with the collected ETH to create an AMM pool.


---

WAIT, how do I add ETH to this strang attractor? 
    
    Just send ETH directly to the contract (or call `deposit`). The minimum and maximum
    amounts may change in the future but are initialized to [0.01 ETH, 0.555 ETH]. 

---

WAIT, but what token will I get back? 

    The first one is a surprise and a work in progress.  

---

WAIT, what if I change my mind? 

    You can call `withdraw` to get your ETH back before the launch. Once a token has launched, 
    the ETH will be sent to the distributor contract and you will not longer be able to withdraw.


---

WAIT, what if I lose my ETH? 

    You probably will, one way or another. 

    This is an experiment, any token(s) that manage to launch will be an experiment and the whole thing is for curiosity and entertainment. 
    
    More formally, by interacting with this contract you agree to hold harmless, defend and indemnify the developers
    from any and all claims made by you arising from injury or loss due to your use of this contract and any other related
    software. There are only minimal safety functions on this contract, and any tokens sent here should be considered permanently 
    unrecoverable.

    Prepare to lose all of your money!
---

WAIT, really?

    You will own nothing and be happy. 
*/


contract StrangeAttractor is Owned(msg.sender) {    
    struct Config {
        uint16 maxLads;
        uint16 minDeposit;
        uint16 maxDeposit;
        bool launched; 
    }

    Config config = Config({maxLads: 200, minDeposit: 10, maxDeposit: 555, launched: false});
    address public distributor; 
    address[] public madlads; 
    mapping(address => uint256) public deposits;

    receive() external payable { 
        deposit(); 
    }

    function deposit() public payable {
        Config memory c = config;

        require(!c.launched, "LAUNCHED");
        unchecked {
        require(madlads.length < c.maxLads, "TOO_MANY_LADS");
            require(msg.value >= uint256(c.minDeposit) * 10**15, "TOO_LOW"); // require that the user sends at least the minimum amount of ETH 
        }
        uint256 oldTotal = deposits[msg.sender];

        if (oldTotal == 0) { // if the user has not deposited anything yet
            madlads.push(msg.sender); // add the user to the list of addresses that have sent ETH to this contract
        }

        uint256 newTotal = oldTotal + msg.value;

        unchecked {
            require(newTotal <= uint256(c.maxDeposit) * 10 ** 15, "TOO_HIGH"); 
        }
        deposits[msg.sender] = newTotal; // increase the counter for the amount being deposited in this transaction
    }

    function reset() external onlyOwner {
        /* 
        Reset the collection contract after launching or in case something has gone wrong. 


        If we haven't launched, refund everyone's ETH, otherwise collect any stray ETH still on contract.
        */
        address madlad; 
        uint256 n = madlads.length;
       
        if (config.launched) {
            while (n > 0) {
                unchecked { --n; }
                madlad = madlads[n];
                deposits[madlad] = 0;
                madlads.pop();
            }
        } else {
            uint256 amount;
            while (n > 0) {
                unchecked { --n; }
                madlad = madlads[n];
                amount = deposits[madlad];
                deposits[madlad] = 0;
                _transfer_eth_if_possible(madlad, amount);
            }
        }
        
        config.launched = false;
        _collect_stray_eth(); 
    } 


    function launch() external onlyOwner {
        require(distributor != address(0), "NO_DISTRIBUTOR");
        require(!config.launched, "LAUNCHED");
        config.launched = true;
        payable(distributor).transfer(address(this).balance); // transfer the ETH to the distributor
    }

    function withdraw() external {
        require(!config.launched, "LAUNCHED"); // user cannot withdraw after the token has been launched
        require(deposits[msg.sender] > 0, "BROKE"); // user cannot withdraw if they have not deposited anything
        _delete_and_refund_if_possible(msg.sender); 
    }

    /*******************************************************************/
    /*                                                                 */
    /*                      UNIT CONVERSION  & PUBLIC VISIBILITY       */
    /*                                                                 */       
    /*******************************************************************/

    function minDepositWei() public view returns (uint256) {
        return uint256(config.minDeposit) * 10**15; // convert minDeposit from thousandths of an ether to wei
    }

    function maxDepositWei() public view returns (uint256) {
        return uint256(config.maxDeposit) * 10**15; // convert minDeposit from thousandths of an ether to wei
    }

    function maxLads() public view returns (uint16) {
        return config.maxLads;
    }

    /*******************************************************************/
    /*                                                                 */
    /*                      CONFIGURATION                              */
    /*                                                                 */       
    /*******************************************************************/
    
    function setMinDeposit(uint16 _minDeposit) public onlyOwner {
        require(_minDeposit > 0, "TOO_LOW");
        require(_minDeposit <= config.maxDeposit, "TOO_HIGH");
        config.minDeposit = _minDeposit;
    }
 
    function setMaxDeposit(uint16 _maxDeposit) public onlyOwner {
        require(_maxDeposit > 0, "TOO_LOW");

        require(_maxDeposit >= config.minDeposit, "TOO_LOW");
        require(_maxDeposit < 1_000_000, "TOO_HIGH");
        config.maxDeposit = _maxDeposit;
    }

    function setMaxLads(uint16 _maxLads) public onlyOwner {
        require(_maxLads > 0, "TOO_LOW");
        require(_maxLads < 10_000, "TOO_HIGH");
        config.maxLads = _maxLads;
    }

    
    function setDistributor(address _distributor) external onlyOwner {
        distributor = _distributor;
    }

    function _find_and_delete(address madlad) internal {
        deposits[madlad] = 0; // set the amount deposited by the user to 0
        // delete sender from list of addresses that have sent ETH to this contract
        uint256 i = 0;
        uint256 n = madlads.length;
        while (i < n) { // iterate over the list of addresses that have sent ETH to this contract
            if (madlads[i] == madlad) { // if the current address is the user's address
                break; 
            }
            unchecked {++i;}
        }
        madlads[i] = madlads[n - 1]; // replace the user's address with the last address in the list
        madlads.pop(); // remove the last address from the list
    }


    function _transfer_eth_if_possible(address madlad, uint256 amount) internal {
          if (address(this).balance >= amount) { // if the contract has enough ETH to refund the user
            payable(madlad).transfer(amount); // transfer the ETH to the user
        }
    }

    function _collect_stray_eth() internal {
          if (address(this).balance > 0) { 
            payable(owner).transfer(address(this).balance); 
        }
    }

    function _delete_and_refund_if_possible(address madlad) internal {
        uint256 amount = deposits[madlad]; // get the amount of ETH deposited by the user
        _find_and_delete(madlad); // delete the user from the list of addresses that have sent ETH to this contract
        _transfer_eth_if_possible(madlad, amount); 
    }
}