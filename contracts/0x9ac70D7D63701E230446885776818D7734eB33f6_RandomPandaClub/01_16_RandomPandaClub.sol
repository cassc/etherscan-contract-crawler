/* 
  Copyright Statement

  Random Panda Club is an NFT project created by PandaDAO. The following is our copyright statement for NFT:

  i. You own the NFT. Each Random Panda is an NFT on the Ethereum blockchain. When you purchase an NFT, you own the underlying Art completely. Ownership of the NFT is mediated entirely by the Smart Contract and the Ethereum Network: at no point may we seize, freeze, or otherwise modify the ownership of any Random Panda.

  ii. Personal Use. Subject to your continued compliance with these Terms, PandaDAO LTD grants you a worldwide, royalty-free license to use, copy, and display the purchased Art, along with any extensions that you choose to create or use, solely for the following purposes: (i) for your own personal, non-commercial use; (ii) as part of a marketplace that permits the purchase and sale of your Random Panda / NFT, provided that the marketplace cryptographically verifies each Random Panda owner’s rights to display the Art for their Random Panda to ensure that only the actual owner can display the Art; or (iii) as part of a third party website or application that permits the inclusion, involvement, or participation of your Random Panda, provided that the website/application cryptographically verifies each Random Panda owner’s rights to display the Art for their Random Panda to ensure that only the actual owner can display the Art, and provided that the Art is no longer visible once the owner of the Random Panda leaves the website/application.

  iii. Commercial Use. Subject to your continued compliance with these Terms, PandaDAO LTD grants you an unlimited, worldwide license to use, copy, and display the purchased Art for the purpose of creating derivative works based upon the Art (“Commercial Use”). Examples of such Commercial Use would e.g. be the use of the Art to produce and sell merchandise products (T-Shirts etc.) displaying copies of the Art. For the sake of clarity, nothing in this Section will be deemed to restrict you from (i) owning or operating a marketplace that permits the use and sale of Random Panda generally, provided that the marketplace cryptographically verifies each Random Panda owner’s rights to display the Art for their Random Panda to ensure that only the actual owner can display the Art; (ii) owning or operating a third party website or application that permits the inclusion, involvement, or participation of Random Panda generally, provided that the third party website or application cryptographically verifies each Random Panda owner’s rights to display the Art for their Random Panda to ensure that only the actual owner can display the Art, and provided that the Art is no longer visible once the owner of the Purchased Random Panda leaves the website/application; or (iii) earning revenue from any of the foregoing.

  iiii. The holder of a Random Panda NFT can claim the CC0 copyright. Once the holder once does so, they will share the copyright of the NFT free to the world. The CC0 copyright is irreversible and will override the copyright notice in the i. ii. iii. content. 
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "./core/ERC721A.sol";

contract RandomPandaClub is Ownable, ERC721A {
    using ECDSA for bytes32;
    using SafeERC20 for IERC20;

    //PANDADAO Treasury.
    address public constant TREASURY_ADD = 0xe19B5757B8C2dD0C9B0fC6D5df739d0d581D0c59;

    //PANDADAO token.
    address public PANDA = 0x3cBb7f5d7499Af626026E96a2f05df806F2200DC;

    //Whitelist Merkle Root
    bytes32 public merkleRoot;

    //Public Sale ETH Price
    uint256 public PS_ETH_PRICE = 0.25 ether;

    //WL PANDA price.
    uint256 public WL_PANDA_PRICE = 50000 * 10 ** 18;

    //Public Sale PANDA price.
    uint256 public PS_PANDA_PRICE = WL_PANDA_PRICE * 120 / 100; 

    //The total quantity for Public sale.
    uint256 public PS_QUANTITY = 5999; 

    //Max panda mint for one address in public sale.
    uint256 public MAX_PANDAMINT_FOR_ADDRESS = 10;

    //Max eth mint for one address in public sale.
    uint256 public MAX_ETHMINT_FOR_ADDRESS = 10;

    //The max quantity for Panda Minting in Public sale.
    uint256 public PS_MAX_PANDAMINT_QUANTITY = 1000;

    //The quantity for WL.
    uint256 public WL_QUANTITY = 3001;

    //MAX Supply.
    uint256 public constant NFT_MAX_INDEX = 10000;

    //How many WL have been minted.
    uint256 public WL_MINTED;

    //How many PS minted by PANDA.
    uint256 public PS_PANDA_MINTED;

    //Takes place time of whitelist sale.
    uint256 public WL_STARTING_TIMESTAMP; 

    //Takes place 24 hours after Whitelist Sale.
    uint256 public PS_STARTING_TIMESTAMP;

    //Whitelist sale period.
    uint256 public WL_PERIOD = 24 * 3600;

    //Public sale period.
    uint256 public PS_PERIOD = 3 * 24 * 3600;

    //Minted by user in WLsale.
    mapping(address => uint256) public userToHasMintedWL;

    //ETHMinted by user in Public sale.
    mapping(address => uint256) public userToHasETHMintedPS;

    //PANDAMinted by user in Public sale.
    mapping(address => uint256) public userToHasPANDAMintedPS;

    //Metadata reveal state
    bool public REVEALED = false;

    //Token Base URI
    string public BASE_URI;

    modifier callerIsUser() {
        if (tx.origin != msg.sender) {
            revert CallIsAnContract(tx.origin, msg.sender);
        }
        _;
    }

    modifier notZeroAddress(address addr) {
        if (addr == address(0)) {
            revert NotZeroAddress(addr);
        }
        _;
    }

    constructor(string memory uri, uint256 ts, bytes32 root) ERC721A("RandomPandaClub", "RPC", 10000) {
        BASE_URI = uri;
        WL_STARTING_TIMESTAMP = ts;
        PS_STARTING_TIMESTAMP = ts + WL_PERIOD;
        merkleRoot = root;

        _safeMint(TREASURY_ADD, 1);
    } 

    /*------------------------------- views -------------------------------*/

    function _baseURI() internal view override(ERC721A) returns (string memory) {
        return BASE_URI;
    }

    /*------------------------------- writes -------------------------------*/

    function publicSaleByETH(uint8 quantity)
        public
        payable
        callerIsUser
    {
        if (block.timestamp < PS_STARTING_TIMESTAMP) {
            revert PSNotStart(block.timestamp, PS_STARTING_TIMESTAMP);
        }

        if (block.timestamp > PS_STARTING_TIMESTAMP + PS_PERIOD) {
            revert PSMintingFinished(block.timestamp, PS_STARTING_TIMESTAMP + PS_PERIOD);
        }

        if (totalSupply() + quantity > PS_QUANTITY + WL_QUANTITY) {
            revert MaxSupplyForPS(totalSupply(), quantity, PS_QUANTITY + WL_QUANTITY);
        }

        if (userToHasETHMintedPS[msg.sender] + quantity > MAX_ETHMINT_FOR_ADDRESS) {
             revert MaxETHMintForAddr(userToHasETHMintedPS[msg.sender], quantity, MAX_ETHMINT_FOR_ADDRESS);
        }

        //Require enough ETH
        if (msg.value < quantity * PS_ETH_PRICE) {
            revert NotEnoughEth(msg.value, quantity * PS_ETH_PRICE);
        }

        userToHasETHMintedPS[msg.sender] += quantity;

        //Mint the quantity
        _safeMint(msg.sender, quantity);

        emit PublicSaleByETH(msg.sender, quantity);
    }

    function publicSaleByPANDA(uint8 quantity)
        public
        callerIsUser
    {
        if (block.timestamp < PS_STARTING_TIMESTAMP) {
            revert PSNotStart(block.timestamp, PS_STARTING_TIMESTAMP);
        }

        if (block.timestamp > PS_STARTING_TIMESTAMP + PS_PERIOD) {
            revert PSMintingFinished(block.timestamp, PS_STARTING_TIMESTAMP + PS_PERIOD);
        }

        if (totalSupply() + quantity > PS_QUANTITY + WL_QUANTITY) {
            revert MaxSupplyForPS(totalSupply(), quantity, PS_QUANTITY + WL_QUANTITY);
        }

        if (PS_PANDA_MINTED + WL_MINTED + quantity > PS_MAX_PANDAMINT_QUANTITY + WL_QUANTITY) {
            revert MaxSupplyForPANDAMINT(PS_PANDA_MINTED + WL_MINTED, quantity, PS_MAX_PANDAMINT_QUANTITY + WL_QUANTITY);
        }

        if (userToHasPANDAMintedPS[msg.sender] + quantity > MAX_PANDAMINT_FOR_ADDRESS) {
             revert MaxPANDAMintForAddr(userToHasPANDAMintedPS[msg.sender], quantity, MAX_PANDAMINT_FOR_ADDRESS);
        }

        //Transfer PANDA
        IERC20(PANDA).safeTransferFrom(msg.sender, address(this), PS_PANDA_PRICE * quantity);

        userToHasPANDAMintedPS[msg.sender] += quantity;
        PS_PANDA_MINTED += quantity;

        //Mint the quantity
        _safeMint(msg.sender, quantity);

        emit PublicSaleByETH(msg.sender, quantity);
    }

    function mintWL(uint256 quantity, uint256 maxQuantity , bytes32[] calldata merkleProof) public callerIsUser {
        if (block.timestamp <= WL_STARTING_TIMESTAMP) {
            revert WLSaleNotStart(block.timestamp, WL_STARTING_TIMESTAMP);
        }

        if (block.timestamp > WL_STARTING_TIMESTAMP + WL_PERIOD) {
            revert WlMintingFinished(block.timestamp, WL_STARTING_TIMESTAMP + WL_PERIOD);
        }

        bytes32 leaf = keccak256(abi.encodePacked(msg.sender, maxQuantity));
        bool valid = MerkleProof.verify(merkleProof, merkleRoot, leaf);
        if (!valid) {
            revert MerkleProofFail();
        }
        
        if (WL_MINTED + quantity > WL_QUANTITY) {
            revert MaxSupplyWl(WL_MINTED + quantity, WL_QUANTITY);
        }

        if (userToHasMintedWL[msg.sender] + quantity > maxQuantity) {
            revert WlMintOverMax(userToHasMintedWL[msg.sender] + quantity);
        }
         
        IERC20(PANDA).safeTransferFrom(msg.sender, address(this), WL_PANDA_PRICE * quantity);

        userToHasMintedWL[msg.sender] = userToHasMintedWL[msg.sender] + quantity;
        WL_MINTED = WL_MINTED + quantity;

        //Mint them
        _safeMint(msg.sender, quantity);

        emit MintWL(msg.sender, quantity);
    }

    //send remaining NFTs to pool
    function devMint(address dev_Add) external onlyOwner {
        if (block.timestamp < PS_STARTING_TIMESTAMP + PS_PERIOD) {
            revert PSNotFinished(block.timestamp, PS_STARTING_TIMESTAMP + PS_PERIOD);
        }
        uint256 leftOver = NFT_MAX_INDEX - totalSupply();
        _safeMint(dev_Add, leftOver);

        emit DevMint(leftOver);
    }

    //send remaining NFTs to pool
    function devMintSafe(address dev_Add, uint leftNum) external onlyOwner {
        if (block.timestamp < PS_STARTING_TIMESTAMP + PS_PERIOD) {//mainnet WL_STARTING_TIMESTAMP + 86400
            revert PSNotFinished(block.timestamp, PS_STARTING_TIMESTAMP + PS_PERIOD);
        }
        uint256 leftOver = NFT_MAX_INDEX - totalSupply();
        if (leftNum > leftOver) {
            revert DevMintOver(leftNum, leftOver);
        }
        _safeMint(dev_Add, leftNum);
        
        emit DevMint(leftNum);
    }

    function withdrawEther() public onlyOwner {
        uint256 finalFunds = address(this).balance;
        payable(TREASURY_ADD).transfer(finalFunds);

        emit WithdrawEther(finalFunds);
    }

    function withdrawERC20(
        uint256 tokenAmount
    ) external onlyOwner
    {
        IERC20(PANDA).transfer(TREASURY_ADD, tokenAmount);

        emit WithdrawERC20(tokenAmount);
    }


    function setStartTime(uint256 startTime) external onlyOwner {
        WL_STARTING_TIMESTAMP = startTime;
        PS_STARTING_TIMESTAMP = startTime + WL_PERIOD;

        emit SetStartTime(startTime); 
    }

    function setWLPeriod(uint256 wlPeriod) external onlyOwner {
        WL_PERIOD = wlPeriod;

        emit SetWLPeriod(wlPeriod); 
    }

    function setPSPeriod(uint256 psPeriod) external onlyOwner {
        PS_PERIOD = psPeriod;

        emit SetPSPeriod(psPeriod); 
    }

    function setETHPrice(uint256 ethPrice) external onlyOwner {
        PS_ETH_PRICE = ethPrice;

        emit SetETHPrice(ethPrice);
    }

    function setPANDAPrice(uint256 pandaPrice) external onlyOwner {
        WL_PANDA_PRICE = pandaPrice;
        PS_PANDA_PRICE = pandaPrice * 120 / 100;

        emit SetPANDAPrice(pandaPrice);
    }

    function setWLSupply(uint256 quantity) external onlyOwner {
        WL_QUANTITY = quantity;

        emit SetWLSupply(quantity);
    }

    function setMaxPandaMint(uint256 maxPandaMint) external onlyOwner {
        MAX_PANDAMINT_FOR_ADDRESS = maxPandaMint;

        emit SetMaxPandaMint(maxPandaMint);
    }

    function setMaxETHMint(uint256 maxETHMint) external onlyOwner {
        MAX_ETHMINT_FOR_ADDRESS = maxETHMint;

        emit SetMaxETHMint(maxETHMint);
    }
    
    function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        merkleRoot = _merkleRoot;

        emit SetMerkleRoot(_merkleRoot);
    }

    function setBaseURI(string memory baseURI_, bool _revealed) external onlyOwner {
        BASE_URI = baseURI_;
        REVEALED = _revealed;

        emit SetBaseURI(baseURI_, _revealed);
    }

    /*------------------------------- errors -------------------------------*/
    
    error CallIsAnContract(address originCaller, address caller);
    error WLSaleNotStart(uint256 timestamp, uint256 startTime);
    error MaxETHMintForAddr(uint256 totalMint, uint256 mintNum, uint256 ethMintNumPerAddr);
    error MaxPANDAMintForAddr(uint256 totalMint, uint256 mintNum, uint256 pandaMintNumPerAddr);
    error NotEnoughEth(uint256 msgValue, uint256 needValue);
    error MaxSupplyWl(uint256 mintNum, uint256 wlNum);
    error MaxSupplyForPS(uint256 totalSupply, uint256 mintNum, uint256 psNum);
    error MaxSupplyForPANDAMINT(uint256 totalSupply, uint256 mintNum, uint256 pandaMintNum);
    error WlMintOverMax(uint256 mintNum);
    error WlMintingFinished(uint256 timestamp, uint256 wlFinishTime);
    error PSNotStart(uint256 timestamp, uint256 psStartTime);     
    error PSMintingFinished(uint256 timestamp, uint256 psFinishTime);
    error PSNotFinished(uint256 timestamp, uint256 psFinishTime);   
    error NotZeroAddress(address addr); 
    error MerkleProofFail();
    error DevMintOver(uint256 leftNum, uint256 leftOver);

    /*------------------------------- events -------------------------------*/
    
    event PublicSaleByETH(address minter, uint256 quantity);
    event MintWL(address minter, uint256 quantity);
    event DevMint(uint256 quantity);
    event WithdrawEther(uint256 quantity);
    event WithdrawERC20(uint256 tokenAmount);
    event SetWLPeriod(uint256 wlPeriod);
    event SetPSPeriod(uint256 psPeriod);
    event SetStartTime(uint256 startTime); 
    event SetWLSupply(uint256 quantity);
    event SetMerkleRoot(bytes32 _merkleRoot);
    event SetBaseURI(string baseURI, bool revealed);
    event SetETHPrice(uint256 ethPrice);
    event SetPANDAPrice(uint256 pandaPrice);
    event SetMaxPandaMint(uint256 maxPandaMint);
    event SetMaxETHMint(uint256 maxETHMint);
}