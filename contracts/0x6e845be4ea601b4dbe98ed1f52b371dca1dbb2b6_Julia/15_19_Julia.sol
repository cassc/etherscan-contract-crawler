// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @artist: Abramo
/// @author: FractalSoft
//  https://julia.fractalnft.art
/* ....................................................'''''''',,''''''''''................
   ................................................''''''''''',;c:;,,'''''''''.............
   ..........................................''''''''''''''',,,;col:;:;,'''''''''..........
   .......................................''''''''''''''''',,,,;:cdxol:;,''''''''''........
   .....................................''''''''''''''''',,,,;::coxkxc;;,,,'''''''''''.....
   ...............................'''''''''''''''''''',,,,,,:lxxxd;;xxdo:,,,'''''''''''....
   ...........................'''''''''''''''''''',,,,,,,,;;:oOo.   .cOx:;,,,,,,'''''''''..
   ........................''''''''''''''''''',,,,,,;;;;;;;::lkc     'xo:;;;;,,,,,,,'''''''
   ....................''''''''''''''''''''',,,,,:ldxxl::oddddxd,   .lxdooodl;;;;:lc,,'''''
   ..................''''''''''''''''''''',,,,,;;:oOOlldxdc;,....   ....,::oxlldddkxc,,''''
   ...............'''''''''''''''''''',,,,,,,,;;;:cxd..,,.                 .'cl,.ckx:,,''''
   ............'''''''''''',,,,,,,,,,,,,,,,,;;coddxxo'                          'odc;,,''''
   ..........''''''''''',,;:;;,,,,,,,,;,,;;;;:dOOd:'                            'loc;;;,'''
   .........''''''''''',,,:oo:::;;coc;;;;;;::lxxx:                               .:loxc,,''
   ......''''''''''''',,,;;lodkkdlxOxddoc:::cxxl'                                 .;oo:,,''
   ....''''''''''''',,,,,;;:cxOccol:,:lldxoldx;                                    :dl;,'''
   .''''''''''''',,,,,;;;;coxko.        .,okOl.                                    ,dl;,'''
   '''''''',,,,,,,,,;;loclokk;             ck,                                    .lo;,,'''
   '''',,,;;;,,;;;;;::lOkoox:               '.                                   .:l;,,,'''
   ,,;;;;:llc:cllccoxxOx,  ..                         Julia Set Collection      ,c:;;,,,'''
   ',,,;;;:::;:::::clodko,,:'                                                   .,c:;,,,'''
   '''''',,,,,,,,,;;;:lxxxxOo.             .l'                                    'lc;,,'''
   ''''''''''',,,,,,,;::::cxko,.          ,x0:                                     :d:,,'''
   ..''''''''''''',,,,,,;;:clkk,.,.. ..':oxdkd.                                    ,do;,,''
   ....''''''''''''',,,,,;;:lkOddxkxodkkdlcclxo,.                                  cdc;,,''
   ......'''''''''''''',,,;odollc:lkdccc:;:::dkkl.                                .:dkc,,''
   .........'''''''''''',,;lc;;;;;;::;;;;;;;:cdOOc.                              ,ddll:,'''
   ............''''''''''',,,,,,,,,,,,,,,,;;;:okkdol,                           ;dd:;,,,'''
   .............'''''''''''''''''',,,,,,,,,,,;;:cclxx,                       .'..:xl;,,''''
   ................''''''''''''''''''''',,,,,,;;;:lkd,;oo;.              ..'lddlcokkc;,''''
   ....................'''''''''''''''''''',,,,,,:dOOkxookxoocc:,   .:cclooxd::cccdo:,'''''
   ......................''''''''''''''''''',,,,,;cccl:;:clccokd.   .ckdc:cc:;;,,;:;,''''''
   .........................'''''''''''''''''''',,,,,,,,;;;;:lkc     'xd:;;,,,,,,,''''''''.
   .............................'''''''''''''''''''',,,,,,,;:okkl;..:dkx:;,,,,''''''''''...
   .................................''''''''''''''''''',,,,,;coodkddkocc;,,,'''''''''''....
   ......................................''''''''''''''''',,,,;;:cxOdc:;,,''''''''''.......
   ..........................................''''''''''''''',,,;:odlll:,,'''''''''.........
   ..............................................'''''''''''',,;ll:;,,,'''''''''...........
   .................................................'''''''''',,;;,,''''''''''.............
   ....................................................'''''''''''''''''''.................

   1978 unique pieces available
*/


import "./ERC721TradableJulia.sol";

contract IERC20 {
    function balanceOf(address account) public view virtual returns (uint256) {}
    function transfer(address _to, uint256 _value) public returns (bool) {}
    function transferFrom(address sender, address recipient, uint256 amount) public returns (bool) {}
}


/**
 * @title Julia
 * Julia - a contract for non-fungible points of the Julia Set.
 */
contract Julia is ERC721TradableJulia {
    using SafeMath for uint256;
    constructor(address _proxyRegistryAddress) ERC721TradableJulia("Julia Set Collection", "JULIA", _proxyRegistryAddress) {}

    bool    private _active;
    uint256 private _activeTime;
    uint256 private cycled = 0;
    uint256 private used_brots = 0;
    uint256 private used_FMJ = 0;
    uint256 private constant max_cycles = 244;
    uint256 public  constant PRICE = 197800000000000000;    // 0.1978 ETH
    uint32  public  constant PRESALE_TIME = 172800;        // 48 hours
    uint8   public  constant MAX_QUANTITY = 20;           // Maximum allowed quantity to purchase per transaction
    uint8   public  constant COMMUNITY_QUOTA = 10;       // 10% of the sale proceeds stays in the community
    
    mapping (uint256 => uint256) claimed;
    mapping (uint256 => uint8  ) cycles;

    address public  MANDELBROT_ADDRESS = 0x6E96Fb1f6D8cb1463E018A2Cc6E09C64eD474deA;
    address public  COMMUNITY_WALLET   = 0x229ddBd9A20e3Df3ab7f540Ec77bEB258476fEe5;
    address public  VIP_PASS_ADDRESS   = 0x5645E72bcBCb9f218268e5DB15F62F016f885984;
    address public  FREE_MINT_ADDRESS  = 0xdd665AFF8C98ee39e4D581caB1e48A1DbE8B055d;

    function baseTokenURI() override public pure returns (string memory) {
        return "https://julia.fractalnft.art/item?token_id=";
    }

    function contractURI() public pure returns (string memory) {
        return "https://julia.fractalnft.art/collection";
    }


    // Sale, pre-sale and free-mints

    function pre_purchase(uint256 fractals) external payable {
        IERC20(VIP_PASS_ADDRESS).transferFrom(msg.sender, address(this), fractals);
        require(_active, "Inactive");
        require(block.timestamp < _activeTime + PRESALE_TIME, "Too late!");
        require(remaining() - fractals >= 1978 + 300 + max_cycles - used_brots - used_FMJ - cycled && fractals <= MAX_QUANTITY, "Too many fractals requested");
        require(msg.value == fractals*PRICE, "Invalid purchase fractals sent");
        for (uint i = 0; i < fractals; i++) {
            mintTo(msg.sender);
            iterate(_currentTokenId);
        }
        give_to_community(fractals);
    }

    function purchase(uint256 fractals) external payable {
        require(_active, "Inactive");
        require(block.timestamp >= _activeTime + PRESALE_TIME, "Purchasing not active");
        require(fractals <= remaining() && fractals <= MAX_QUANTITY, "Too many fractals requested");
        require(msg.value == fractals*PRICE, "Invalid purchase amount sent");
        for (uint i = 0; i < fractals; i++) {
            mintTo(msg.sender);
            iterate(_currentTokenId);
        }
        give_to_community(fractals);
    }

    function claim_from_brots(uint256[] memory brots) external {
        require(_active, "Inactive");
        require(block.timestamp < _activeTime + PRESALE_TIME, "Too late!");
        require(brots.length>0, "Please input the ids of your Mandelbrots");
        
        uint256 verified = 0;

        for (uint i = 0; i < brots.length; i++) {
            require(brots[i]>0 && brots[i]<=1978, "Invalid Mandelbrot id");
            require(claimed[brots[i]]==0, "Mandelbrot already claimed");
            mintTo(msg.sender);
            iterate(_currentTokenId);
            used_brots++;
        }   

        uint256 owned;
        uint256 j = 0;
        while (verified < brots.length) {
            owned = IERC721Enumerable(MANDELBROT_ADDRESS).tokenOfOwnerByIndex(msg.sender, j);
            for (uint k = 0; k < brots.length; k++) {
                if (brots[k]==owned && claimed[owned]==0){
                    verified++;
                    claimed[owned] = _currentTokenId;
                    k = brots.length;
                }
            }
            j++;
        }

        require(verified==brots.length, "You don't own all the Mandelbrots you are claiming");
    }

    function claim_from_free_mint(uint256 fractals) external {
        require(_active, "Inactive");
        require(block.timestamp < _activeTime + PRESALE_TIME, "Too late!");
        IERC20(FREE_MINT_ADDRESS).transferFrom(msg.sender, address(this), fractals);
        for (uint i = 0; i < fractals; i++) {
            mintTo(msg.sender);
            iterate(_currentTokenId);
            used_FMJ++;
        }   
    }




    // Views

    function active() external view returns(bool) {
        return _active;
    }

    function timeToSale() external view returns(uint256) {
        require(_active, "Inactive");
        if (block.timestamp >= (_activeTime + PRESALE_TIME)) return 0;
        return (_activeTime + PRESALE_TIME) - block.timestamp;
    }

    function was_brot_used(uint256 brot_id) external view returns(bool) {
        require(_active, "Inactive");
        if (claimed[brot_id]>0) return true;
        return false;
    }

    function claimable_brots() external view returns(uint256) {
        require(_active, "Inactive");
        return 1978 - used_brots;
    }


    // Utils

    function give_to_community(uint256 fractals) internal {
        uint256 amount = (fractals*PRICE*COMMUNITY_QUOTA).div(100);
        payable(COMMUNITY_WALLET).transfer(amount);
    }

    function iterate(uint256 token_id) internal {
        if (cycles[token_id]==1 && cycled<max_cycles) {
            mintTo(msg.sender);
            cycled++;
            iterate(_currentTokenId);
        }
    }



    // Owner's functions

    function activate() external onlyOwner {
        require(!_active, "Already active");
        _activeTime = block.timestamp;
        _active = true;
    }

    function change_active_time(uint256 activeTime) external onlyOwner {
        _activeTime = activeTime;
    }

    function premine(uint256 fractals) external onlyOwner {
        require(!_active, "Already active");
        for (uint i = 0; i < fractals; i++) {
            mintTo(msg.sender);
        }
    }
    
    function withdraw(address payable recipient, uint256 amount) external onlyOwner {
        recipient.transfer(amount);
    }

    function pause_sale() external onlyOwner {
        _active = false;
    }

    function resume_sale() external onlyOwner {
        _active = true;
    }

    function activale(uint256[] memory ids) external onlyOwner {
        for (uint i=0; i < ids.length; i++) {
              cycles[ids[i]] = 1;
          }
    }

}