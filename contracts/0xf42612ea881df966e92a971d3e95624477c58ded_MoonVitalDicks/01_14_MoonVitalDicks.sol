// SPDX-License-Identifier: MIT
//'##::::'##::'#######:::'#######::'##::: ##:'##::::'##:'####:'########::::'###::::'##:::::::'########::'########::'####::'######::'##:::'##::'######::
// ###::'###:'##.... ##:'##.... ##: ###:: ##: ##:::: ##:. ##::... ##..::::'## ##::: ##::::::: ##.... ##: ##.... ##:. ##::'##... ##: ##::'##::'##... ##:
// ####'####: ##:::: ##: ##:::: ##: ####: ##: ##:::: ##:: ##::::: ##:::::'##:. ##:: ##::::::: ##:::: ##: ##:::: ##:: ##:: ##:::..:: ##:'##::: ##:::..::
// ## ### ##: ##:::: ##: ##:::: ##: ## ## ##: ##:::: ##:: ##::::: ##::::'##:::. ##: ##::::::: ##:::: ##: ##:::: ##:: ##:: ##::::::: #####::::. ######::
// ##. #: ##: ##:::: ##: ##:::: ##: ##. ####:. ##:: ##::: ##::::: ##:::: #########: ##::::::: ##:::: ##: ##:::: ##:: ##:: ##::::::: ##. ##::::..... ##:
// ##:.:: ##: ##:::: ##: ##:::: ##: ##:. ###::. ## ##:::: ##::::: ##:::: ##.... ##: ##::::::: ##:::: ##: ##:::: ##:: ##:: ##::: ##: ##:. ##::'##::: ##:
// ##:::: ##:. #######::. #######:: ##::. ##:::. ###::::'####:::: ##:::: ##:::: ##: ########: ########:: ########::'####:. ######:: ##::. ##:. ######::
//..:::::..:::.......::::.......:::..::::..:::::...:::::....:::::..:::::..:::::..::........::........:::........:::....:::......:::..::::..:::......:::
//@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
//@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
//@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
//@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
//@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ ,@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
//@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@     @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
//@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@       @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
//@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@     @@ @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
//@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@  &@  @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
//@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@  @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
//@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
//@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
//@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@     @@@@@@@       @@@@@@@@@@@@@@@@@@@@@@@@@@
//@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@.(&&@@@@@@@@@@@@@&/     [email protected]@@@@@@@@@@@@@@@@@@@@@@
//@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ @@@@@@@@@@@@@@@@@@(  @@    @@@@@@@@@@@@@@@@@@@@@@
//@@@@@@@@@@@@@@@@@@@@@@@@@@@ @@@@@@@@@@@@@@@@@@@@@@@@@@@    @@@@@@@@@@@@@@@@@@@@@
//@@@@@@@@@@@@@@@@@@@@@@@@ @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@    @@@@@@@@@@@@@@@@@@@
//@@@@@@@@@@@@@@@@@@@@@@& @@@@@@@@@@@@@@@@@@@@@@@@@( @@@@@@@    @@@@@@@@@@@@@@@@@@
//@@@@@@@@@@@@@@@@@@@@@ [email protected]@@@@@@@@@@@@@@@@@@@@@@@@@( @@@@@@@    @@@@@@@@@@@@@@@@@@
//@@@@@@@@@@@@@@@@@@@@@ [email protected]@@@@@@@@@@@@@@@@@@@@@@@@@( @@@@@@@    @@@@@@@@@@@@@@@@@@
//@@@@@@@@@@@@@@@@@@@@ @@@@@@@@@@@@@@@@@@@@@@@@@@@@/ @@@@@@@@     @@@@@@@@@@@@@@@@
//@@@@@@@@@@@@@@@@@@@@ @@@@@@@@@@@@@@@@@@@@@@@@@@@@( @@@@@@@@     @@@@@@@@@@@@@@@@
//@@@@@@@@@@@@@@@@@@@@ @@@@@@@@@@@@@@@@@@@@@@@@@@@@(  @@@@@@@     @@@@@@@@@@@@@@@@
//@@@@@@@@@@@@@@@@@@@@@@& @@@@@@@@@@@@@@@@@@@@@@@@              @@@@@@@@@@@@@@@@@@
//@@@@@@@@@@@@@@@@@@@@@@@@                        @@@@       @@@@@@@@@@@@@@@@@@@@@
//@@@@@@@@@@@@@@@@@@@@@@@@ @@@  @@@@@@@@@@@ @@@@@@@( @@@    @@@@@@@@@@@@@@@@@@@@@@
//@@@@@@@@@@@@@@@@@@@@@@@@ @@@  @@@@@@@@@@@@  @@@@@( @@@    @@@@@@@@@@@@@@@@@@@@@@
//@@@@@@@@@@@@@@@@@@@@@@@@ @@ @@@@* @@@@@@@ @@ @@@@( @@@    @@@@@@@@@@@@@@@@@@@@@@
//@@@@@@@@@@@@@@@@@@@@@@@@ @@@@@@@@@ @@@@@ @@@ @@@@/ @@@    @@@@@@@@@@@@@@@@@@@@@@
//@@@@@@@@@@@@@@@@@@@@@@@@ @@@  @@@@ @@@@@@@@@@@@@@@@@@@    @@@@@@@@@@@@@@@@@@@@@@
//@@@@@@@@@@@@@@@@@@@@@@@@ @@@  @@@@ @@@@@@@@@@@@@@( @@@    @@@@@@@@@@@@@@@@@@@@@@
//@@@@@@@@@@@@@@@@@@@@@@@@ @@@@@@@@@@  @@@@@@@ @@@@@@@@@    @@@@@@@@@@@@@@@@@@@@@@

pragma solidity ^0.8.0;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "./ERC721A.sol";

contract MoonVitalDicks is  Ownable,ERC721A,ReentrancyGuard {

    mapping (address => uint256) public Minted;
    bytes32 public merkleRoot;
    bool public MintStatusPublic = false;
    bool public MintStatusWL = false;
    uint public MintPrice = 0.0022 ether;
    string public baseURI;  
    uint public freeMint = 2;
    uint public maxMintPerTx = 22;  
    uint public maxSupply = 5000;
    uint public teamSupply = 50;
    uint public mintSupply = 4950;

    constructor() ERC721A("Moon Vital Dicks", "MVD",50,5000){}

    function mint(uint256 qty) external payable
    {
        require(MintStatusPublic , "MVD:  Minting Public Pause");
        _safemint(qty);
    }
    
    function WLmint(uint256 qty, bytes32[] calldata _merkleProof) external payable
    {
        require(MintStatusWL , "MVD:  Minting Whitelist Pause");
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(MerkleProof.verify(_merkleProof, merkleRoot, leaf), "Punko Pixel: Not in whitelisted");
        _safemint(qty);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function setPublicMinting() external onlyOwner {
        MintStatusPublic  = !MintStatusPublic ;
    }

    function setWLMinting() external onlyOwner {
        MintStatusWL  = !MintStatusWL ;
    }
    
    function setBaseURI(string calldata baseURI_) external onlyOwner {
        baseURI = baseURI_;
    }

    function setPrice(uint256 price_) external onlyOwner {
        MintPrice = price_;
    }

    function setmaxMintPerTx(uint256 maxMintPerTx_) external onlyOwner {
        maxMintPerTx = maxMintPerTx_;
    }

    function setMaxFreeMint(uint256 qty_) external onlyOwner {
        freeMint = qty_;
    }

    function setmaxSupply(uint256 qty_) external onlyOwner {
        mintSupply = qty_;
    }

    function airdrop(address to ,uint256 qty) external onlyOwner
    {
        _safeMint(to, qty);
    }

    function OwnerBatchMint(uint256 qty) external onlyOwner
    {
        _safeMint(msg.sender, qty);
    }

    function withdraw() public onlyOwner {
        payable(msg.sender).transfer(payable(address(this)).balance);
    }

    function _safemint(uint256 qty) internal
    {
        require(qty <= maxMintPerTx, "MVD:  Limit Per Transaction");
        require(totalSupply() + qty <= mintSupply,"MVD: Soldout");
        if(Minted[msg.sender] < freeMint) 
        {
            if(qty < freeMint) qty = freeMint;
           require(msg.value >= (qty - freeMint) * MintPrice,"MVD: Fund not enough");
            Minted[msg.sender] += qty;
           _safeMint(msg.sender, qty);
        }
        else
        {
           require(msg.value >= qty * MintPrice,"MVD: Fund not enough");
            Minted[msg.sender] += qty;
           _safeMint(msg.sender, qty);
        }
    }

}