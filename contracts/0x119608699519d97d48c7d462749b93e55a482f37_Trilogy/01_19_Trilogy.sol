// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @artist: Abramo
/// @author: FractalSoft
//  https://mandelbrot.fractalnft.art
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
   ,,;;;;:llc:cllccoxxOx,  ..                   Mandelbrot Trilogy Collection   ,c:;;,,,'''
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


import "./ERC721TradableTrilogy.sol";

contract IERC20 {
    function balanceOf(address account) public view virtual returns (uint256) {}
    function transfer(address _to, uint256 _value) public returns (bool) {}
    function transferFrom(address sender, address recipient, uint256 amount) public returns (bool) {}
}

contract NFT {
    function transferFrom(address from, address to, uint256 tokenId) public {}
    function getApproved(uint256 tokenId) external view returns (address operator) {}
    function ownerOf(uint256 tokenId) external view returns (address owner) {}
}

contract ITrilogyFinder {
    function get_trilogy_id(uint256 token_id) public view returns(uint16) {}
}

/**
 * @title Trilogy
 * Trilogy - a contract for non-fungible Mandelbrot Trilogies
 */
contract Trilogy is ERC721TradableTrilogy {
    using SafeMath for uint256;
    constructor(address _proxyRegistryAddress) ERC721TradableTrilogy("Mandelbrot Trilogy Collection", "TRI", _proxyRegistryAddress) {}

    bool    private _active;
    //uint256 private claimed = 0;

    mapping (uint256 => uint256) token_to_trilogy;
    mapping (uint256 => uint256) brot_to_trilogy;

    // LIVE
    address public  constant MANDELBROT_ADDRESS = 0x6E96Fb1f6D8cb1463E018A2Cc6E09C64eD474deA;
    address public  constant JULIA_ADDRESS      = 0x6e845bE4ea601B4Dbe98ED1f52b371dca1Dbb2b6;
    address private constant FINDER_1_ADDRESS   = 0xac69bbAC27a85F3d762aC0d083183D646452c9Df;
    address private constant FINDER_2_ADDRESS   = 0xE74CcB76b1453F5B6b5B43aC99E8E89b352545dC;
    address private constant FINDER_3_ADDRESS   = 0xc8cAC2F64850F705a7d1AA90aA73eebCb383c002;
    address private constant FINDER_4_ADDRESS   = 0x251A6cA8350c70D8A66abce678428a6EEB2d3683;

    // // TESTNET
    // address public  MANDELBROT_ADDRESS = 0x48Eff4D6263a2237142e89d97A688845f8E814EE;
    // address public  JULIA_ADDRESS      = 0xdd665AFF8C98ee39e4D581caB1e48A1DbE8B055d;
    // //address private FINDER_1_ADDRESS   = 0xA9123249e834247AF12af348FA1c2C9Af2AD8Bf9;
    // address private FINDER_2_ADDRESS   = 0x17f9c7657055d5a3d9EA41CBC876311b454C54Fd;
    // address private FINDER_3_ADDRESS   = 0xa5C99F04CBe68486A330dfDbA18842aD256C410A;
    // address private FINDER_4_ADDRESS   = 0x1984b71Aa97cbaee79719CD210607A9c894539b2;

    // // TEST-ONLY
    // address private FINDER_1_ADDRESS   = 0x2aBBD2ad2434f0909977FeB2ceaF43537f7D5138;
    

    event TrilogyFormed(uint256 token_id, uint256 trilogy_id, uint256 julia_A);


    function find_id(uint256 owned) internal view returns(uint256 _trilogy_id) {
        uint256 owned_reduced;
        if (owned%(250*5)>0) owned_reduced = owned%(250*5);
        else owned_reduced = 250*5;
        if      (owned<=250*5*1 ) return uint256(ITrilogyFinder(FINDER_1_ADDRESS).get_trilogy_id(owned_reduced));
        else if (owned<=250*5*2 ) return uint256(ITrilogyFinder(FINDER_2_ADDRESS).get_trilogy_id(owned_reduced));
        else if (owned<=250*5*3 ) return uint256(ITrilogyFinder(FINDER_3_ADDRESS).get_trilogy_id(owned_reduced));
        else if (owned<=250*5*4 ) return uint256(ITrilogyFinder(FINDER_4_ADDRESS).get_trilogy_id(owned_reduced));
    }

    
    function claim_trilogy(uint256 trilogy_id, uint256 julia_A, uint256 julia_B) public {

        require(check_trilogy_holder(trilogy_id, julia_A, julia_B, msg.sender));
        
        // Mint the trilogy
        mintTo(msg.sender);

        // Burn one Julia (requires approve)
        NFT(JULIA_ADDRESS).transferFrom(msg.sender, address(0x000000000000000000000000000000000000dEaD), julia_B );

        // Fire the event
        emit TrilogyFormed(_currentTokenId, trilogy_id, julia_A);

        token_to_trilogy[_currentTokenId] = trilogy_id;
        brot_to_trilogy[trilogy_id] = _currentTokenId;
        
        //claimed++;
    }


    function check_trilogy_holder(uint256 trilogy_id, uint256 julia_A, uint256 julia_B, address holder) public view returns (bool) {

        require(_active, "Contract not active");
        require(!was_trilogy_claimed(trilogy_id), "This trilogy was already minted");
        
        require(trilogy_id>0 && trilogy_id<=1978, "Please enter a valid Mandelbrot id");
        require(julia_A   >0 && julia_A   <=4200, "Please enter a valid Julia id");
        require(julia_B   >0 && julia_B   <=4200, "Please enter a valid Julia id");

        // Verify Brot and Julias
        require(NFT(MANDELBROT_ADDRESS).ownerOf(trilogy_id)==holder, "You don't own this Mandelbrot");
        require(NFT(JULIA_ADDRESS     ).ownerOf(julia_A   )==holder, "You don't own this Julia");
        require(NFT(JULIA_ADDRESS     ).ownerOf(julia_B   )==holder, "You don't own this Julia");

        require(find_id(julia_A)==trilogy_id, "Wrong Julia for this trilogy");
        require(find_id(julia_B)==trilogy_id, "Wrong Julia for this trilogy");

        return true;
    }

    function check_trilogy(uint256 trilogy_id, uint256 julia_A, uint256 julia_B) public view returns (bool) {
        return check_trilogy_holder(trilogy_id, julia_A, julia_B, msg.sender);
    }

    function baseTokenURI() override public pure returns (string memory) {
        return "https://trilogy.fractalnft.art/item?token_id=";
    }

    function contractURI() public pure returns (string memory) {
        return "https://trilogy.fractalnft.art/collection";
    }


    // Views

    function active() external view returns(bool) {
        return _active;
    }


    function get_trilogy_id(uint256 token_id) external view returns(uint256 _trilogy_id) {
        return token_to_trilogy[token_id];
    }

    function was_trilogy_claimed(uint256 trilogy_id) public view returns(bool) {
        require(_active, "Inactive");
        if (brot_to_trilogy[trilogy_id]>0) return true;
        return false;
    }


    // Owner's functions

    function activate() external onlyOwner {
        require(!_active, "Already active");
        _active = true;
    }
    
    function withdraw(address payable recipient, uint256 amount) external onlyOwner {
        recipient.transfer(amount);
    }

    function pause() external onlyOwner {
        _active = false;
    }

    function resume() external onlyOwner {
        _active = true;
    }

    function test_finder(uint256 owned) external onlyOwner view returns(uint256 _trilogy_id) {
        return find_id(owned);
    }

}