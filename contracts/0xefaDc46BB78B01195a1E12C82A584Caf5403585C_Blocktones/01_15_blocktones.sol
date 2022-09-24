// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;                                                                         
        //                        @(%&&&&&&&&&%%%%##,/%                            
        //                    &&&&&&&&&%%%%%%%###(((//***,/                        
        //                 @@%%%%%%%%%%%%#####(((///***,,,,,,/                     
        //               @%%%%%%%%%%%####(#(((////***,,,,,,,...*                   
        //             @%%%%%%%%%%#%###((((((////****,,,,,,......#                 
        //           [email protected]%%%%%%%%%%######((((/////***,,,,,,,,.,...../                
        //          [email protected]%%%%%%%%#%#######,%&&&@%*@@%/**,,,,,,........&               
        //         [email protected]&%%%%%%%%%%#####(%           %@/*,,,,,.........%              
        //         *@&&%%%%%%%%%####(*             #@(*,,,,,,.......%              
        //           .                                ..                           
        //         .&@@          &@%(/%%&&&&&@@@@@@@@@&&&&&&&&&&&&#(               
        //       [email protected]&&&&,%      @&######((((((((//////*********,,,,,,/              
        //      ,@&&&&&&&&%@&%%%######(((((((/////*********,,,,,,,,,/              
        //     /@&&&&&&&&&%%%%%%######(((((/////*******,,,,,,,,,.,../              
        //    [email protected]&&&&&&&&&&&%%%%%#%####(((((/////****,,,,,,,,,,....../              
        //        [email protected]&&&&&&&&%%%%%######(((((///*****,,,,,,,,,.......#              
        //         /@&&&&&&&&%%%%%%#####(((((////****,,*,,,,,,,.../@               
        //         *@&&&&&&&&&&%%%%%#####((((/////*****,,,,,,,,,%                  
        //         .&@&&&&&&&&&&%%%%%%####((#((//////*****,,,#&                    
        //                  [email protected]&&&%%%%%####(((((//////*******&                      
        //                   [email protected]&&&%%%%%#####((((//////****,@                       
        //                   [email protected]&&&%%%%%######(((((////****(#                       
        //                    [email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@&                                                                                       
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract Blocktones is ERC721Enumerable, Ownable {
    constructor() ERC721("Blocktones", "BLOCKTONES") {}
    using Counters for Counters.Counter;

    // meta
    Counters.Counter private supply;
    string private _baseTokenURI;
    address public withdrawalAddress = 0x3984d3614f5cb6120C2097FeB664B674a5a63183;
    
    // mint details
    uint256 public priceReduced = 0.08 ether;
    uint256 public price = 0.11 ether;
    uint256 public maxSupply = 4444;
    uint256 public perWalletLimit = 2;

    // merkle roots
    bytes32 public merkleRootWindow1; // window1
    bytes32 public merkleRootReduced; // phase4
    bytes32 public merkleRootWL; // whitelist

    // mint toggles
    bool public reducedLive;
    bool public window1Live;
    bool public whitelistLive;
    bool public publicLive;

    // per user minting tracker
    mapping(address => uint256) mintedCount;

    event Minted(address indexed to, uint256 amount);

    // override to save gas
    function totalSupply() public view override returns (uint256) {
        return supply.current();
    }

    /*
    * Minting management
    */
    // mint function for Phase 4
    function reducedMint(uint256 quantity, bytes32[] calldata proof) external payable isValidMint(quantity, priceReduced){
        require(reducedLive, 'Phase not live');
        require(verify(merkleRootReduced, keccak256(abi.encodePacked(msg.sender)), proof));
        mint(msg.sender, quantity);
    }    
    // mint function for rest of Window 1
    function window1Mint(uint256 quantity, bytes32[] calldata proof) external payable isValidMint(quantity, price) {
        require(window1Live, 'Phase not live');
        require(verify(merkleRootWindow1, keccak256(abi.encodePacked(msg.sender)), proof));
        mint(msg.sender, quantity);
    }    
    // mint function for Whitelist (Window 2)
    function whitelistMint(uint256 quantity, bytes32[] calldata proof) external payable isValidMint(quantity, price) {
        require(whitelistLive, 'Phase not live');
        require(verify(merkleRootWL, keccak256(abi.encodePacked(msg.sender)), proof));
        mint(msg.sender, quantity);
    }

    // mint function for Public
    function publicMint(uint256 quantity) external payable isValidMint(quantity, price) {
        require(publicLive, 'Phase not live');
        mint(msg.sender, quantity);
    }

    function mint(address to, uint256 quantity) internal {
        require(totalSupply() + quantity <= maxSupply, 'Out of supply');
        mintedCount[to] += quantity;
        for (uint i; i < quantity; i++) {
            _safeMint(to, totalSupply());
            supply.increment();
        }
        emit Minted(msg.sender, quantity);
    }

    modifier isValidMint(uint256 quantity, uint256 _price) {
        require(quantity > 0, 'Invalid quantity entered');
        require(mintedCount[msg.sender] + quantity <= perWalletLimit, 'Individual mint limit exceeded');
        require(msg.value >= quantity * _price, 'Not enough eth');
        _;
    }

    /*
    * Utility functions
    */
    function adminMint(address to, uint256 quantity) external onlyOwner {
        mint(to, quantity);
    }

    // will be important later to get tokens by user
    function tokensOwnedByAddress(address user) external view returns (uint256[] memory){
        uint256 balance = balanceOf(user);
        uint256[] memory tokens = new uint256[](balance);
        for (uint i; i < balance; i++) {
            tokens[i] = (tokenOfOwnerByIndex(user, i));
        } 
        return tokens;
    }

    function verify(
        bytes32 root,
        bytes32 leaf,
        bytes32[] memory proof
    ) public pure returns (bool) {
        return MerkleProof.verify(proof, root, leaf);
    }
    // Base URI
    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        return string(abi.encodePacked(super.tokenURI(tokenId), '.json'));
    }

    /*
    * Setters
    */
    function setBaseURI(string calldata baseURI) public onlyOwner {
        _baseTokenURI = baseURI;
    }
    function setPriceReduced(uint256 _price) external onlyOwner {
        priceReduced = _price;
    }
    function setPrice(uint256 _price) external onlyOwner {
        price = _price;
    }
    function setMaxSupply(uint256 _maxSupply) external onlyOwner {
        maxSupply = _maxSupply;
    }
    function setMerkleRootReduced(bytes32 _root) external onlyOwner {
        merkleRootReduced = _root;
    }
    function setMerkleRootWindow1(bytes32 _root) external onlyOwner {
        merkleRootWindow1 = _root;
    }
    function setMerkleRootWL(bytes32 _root) external onlyOwner {
        merkleRootWL = _root;
    }
    function setWindow1Live(bool _set) external onlyOwner {
        window1Live = _set;
    }
    function setReducedLive(bool _set) external onlyOwner {
        reducedLive = _set;
    }
    function setWhitelistLive(bool _set) external onlyOwner {
        whitelistLive = _set;
    }
    function setPublicLive(bool _set) external onlyOwner {
        publicLive = _set;
    }
    function setPerWalletLimit(uint256 _limit) external onlyOwner {
        perWalletLimit = _limit;
    }
    function setWithdrawalAddress(address _addr) external onlyOwner {
        withdrawalAddress = _addr;
    }

    function withdraw() public onlyOwner {
        uint256 total = payable(address(this)).balance;
        (bool success, ) = payable(withdrawalAddress).call{ value: total }("");
        require(success, "eth withdraw failed");
    }
}