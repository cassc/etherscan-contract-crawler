// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBase.sol";

interface IERC20 {
    function transfer(address recipient, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

contract Tri3es is Ownable, ReentrancyGuard, ERC721A, VRFConsumerBase {
    using Strings for uint256;
    using ECDSA for bytes32;

    // Public variables
    uint256 public constant GENESIS_RESERVED_SUPPLY = 626;
    uint256 public constant MAX_NFT_SUPPLY = 10000;
    uint256 public constant MAX_NFT_SUPPLY_FOR_MINTS = 9374;
    uint256 public mintPrice = 0.085 ether;
    uint256[] public ts = new uint256[](4);
    string public _baseTokenURI;
    uint256 public shiftIndex;
    uint256 public genesisSupply;
    string public provenance;
    address private signerAddress;
    mapping (address => uint256) public balancePresale;
    mapping (address => uint256) public isGenesisClaimed;
    mapping (address => uint256) public isFreeClaimed;
    
    // Team
    address[] public payees;
    mapping(address => uint256) private shares;
    uint256 private totalShares;

    // VRF https://docs.chain.link/docs/vrf-contracts/v1/
    address immutable private linkToken;
    address immutable private linkCoordinator;

    /**
     * @dev Initialize
     */
    constructor(string memory baseURI, 
                address[] memory _team,
                uint256[] memory _shares,
                address _signerAddress,
                uint256[] memory _ts,
                address _linkToken, 
                address _linkCoordinator) 
        ERC721A("Tri3es", "Tri3es") 
        VRFConsumerBase(_linkCoordinator, _linkToken)
    {
        // OZ splitter copy paste
        require(_team.length == _shares.length, "Payees and shares length mismatch");
        require(_team.length > 0, "No payees");
        for (uint256 i = 0; i < _team.length; i++) {
            _addPayee(_team[i], _shares[i]);
        }

        // set url
        setBaseURI(baseURI);

        // set signer address
        setSignerAddress(_signerAddress);

        // set ts
        setTs(_ts);

        // VRF
        linkToken = _linkToken;
        linkCoordinator = _linkCoordinator;
    }

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

    /**
     * @dev Changes signer address. In case of emergency
     */
    function setSignerAddress(address addr) public onlyOwner {
        signerAddress = addr;
    }

    /**
     * @dev Gets base url
     */
    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    /**
     * @dev Sets base url. In case of emergency
     */
    function setBaseURI(string memory baseURI) public onlyOwner {
        _baseTokenURI = baseURI;
    }

    /**
     * @dev Sets price. In case of emergency
     */
    function setPrice(uint256 _price) public onlyOwner {
        mintPrice = _price;
    }

    /**
    * @dev Sets timestamp of mints.  0 - genesis; 1 - presale,  2 - sale, 3 - promo free. In case of emergency / pause
    */
    function setTs(uint256[] memory _ts) public onlyOwner {
        ts = _ts;
    }

    /**
     * @dev Ipfs CID of metadatas is set before reveal
    */
    function setProvenanceHash(string calldata provenanceHash) external onlyOwner {
        provenance = provenanceHash;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        if (shiftIndex != 0){
            uint256 shiftedId = (tokenId + shiftIndex) % (MAX_NFT_SUPPLY);
            return string(abi.encodePacked(_baseURI(), "nft/", shiftedId.toString()));
        } else {
            return string(abi.encodePacked(_baseURI(), "not_revealed/", tokenId.toString()));
        }
    }

    /**
    * @dev Mints for airdrops and promos. Only one time called after SC deployed
    */
    function mintAirdrop(uint256 quantity, address reciever) external onlyOwner {
        require(totalSupply() == 0, "Could only be called once");
        _safeMint(reciever, quantity);
    }

    /**
    * @dev Mints for public launch
    */
    function mint(uint256 quantity) external nonReentrant payable callerIsUser {
        require(totalSupply() - genesisSupply + quantity <= MAX_NFT_SUPPLY_FOR_MINTS, "Not enough NFTs left");
        require(block.timestamp >= ts[2] && ts[2] != 0, "Public sales are paused / not started");
        require(quantity<= 3, "Amount of minted NFTs at once should be less or equal to 3");
        require(msg.value == mintPrice * quantity, "Wrong ETH amount");

        // mint
        _safeMint(_msgSender(), quantity);
    }

    /**
    * @dev Mints for WL
    */
    function mintPresale(uint256 quantity, bytes calldata _signature) external nonReentrant payable callerIsUser {
        require(totalSupply() - genesisSupply +  quantity <= MAX_NFT_SUPPLY_FOR_MINTS, "Not enough NFTs left");
        require(block.timestamp >= ts[1] && ts[1] != 0, "Presale is paused / not started");
        require(msg.value == mintPrice * quantity, "Wrong ETH amount");
        require(signerAddress == keccak256(abi.encode("Tri3es_mintPresale_", _msgSender())).toEthSignedMessageHash().recover(_signature), "You are not whitelisted");

        // check max mints per wallet
        require(balancePresale[_msgSender()] + quantity <= 2, "You can presale mint only 2 NFTs in total");

        // add to wl balance
        balancePresale[_msgSender()] = balancePresale[_msgSender()] + quantity;

        // mint
        _safeMint(_msgSender(), quantity);
    }

    /**
    * @dev Mints for free promo. No reserved mints
    */
    function mintForFree(uint256 quantity, bytes calldata _signature) external nonReentrant callerIsUser {
        require(totalSupply() - genesisSupply + quantity <= MAX_NFT_SUPPLY_FOR_MINTS, "Not enough NFTs left");
        require(block.timestamp >= ts[3] && ts[3] != 0, "Free mint is paused / not started");
        require(signerAddress == keccak256(abi.encode("Tri3es_mintForFree_", _msgSender(), quantity)).toEthSignedMessageHash().recover(_signature), "Signature is wrong");
        require(isFreeClaimed[_msgSender()] == 0, "You already claimed free NFTs");

        // want to save q amount
        isFreeClaimed[_msgSender()] = quantity;

        // mint
        _safeMint(_msgSender(), quantity);
    }

    /**
    * @dev Mints for free genesis. Genesis holders has reserved N of mints, even if soldout
    */
    function mintGenesis(uint256 quantity, bytes calldata _signature) external nonReentrant callerIsUser {
        // shouldn't be the case, as we take snaphot 1 time and verify the exact number of holders.
        require(genesisSupply + quantity <= GENESIS_RESERVED_SUPPLY, "Not enough NFTs left");
        require(block.timestamp >= ts[0] && ts[0] != 0, "Genesis mint is paused / not started");
        require(signerAddress == keccak256(abi.encode("Tri3es_mintGenesis_", _msgSender(), quantity)).toEthSignedMessageHash().recover(_signature), "Signature is wrong");
        require(isGenesisClaimed[_msgSender()] == 0, "You already claimed free NFTs");

        // update total genesis supply
        unchecked {
            genesisSupply = genesisSupply + quantity;
        }
        // want to save q amount
        isGenesisClaimed[_msgSender()] = quantity;

        // mint
        _safeMint(_msgSender(), quantity);
    }

    /**
    * @dev Withdraw ether. Release func from OZ Payment Splitter
    */
    function withdraw() public {
        require(shares[_msgSender()] > 0, "Only team members are allowed");
        // get balance 
        uint256 balance = address(this).balance;
        require(balance > 0, "Nothing to withdraw");
        for (uint256 i = 0; i < payees.length; i++) {
            Address.sendValue(payable(payees[i]), (balance / totalShares) * shares[payees[i]]);
        }
    }

    /**
     * @dev Withdraw ERC20
    */
    function withdrawERC20(address tokenAddress) public {
        require(shares[_msgSender()] > 0, "Only team members are allowed");
        // get balance 
        uint256 balance = IERC20(tokenAddress).balanceOf(address(this));
        require(balance > 0, "Nothing to withdraw");
        for (uint256 i = 0; i < payees.length; i++) {
            IERC20(tokenAddress).transfer(payees[i], (balance / totalShares) * shares[payees[i]]);
        }
    }

    /**
    * @dev Add Payee. _addPayee func from OZ Payment Splitter
    */
    function _addPayee(address account, uint256 shares_) private {
        require(account != address(0), "Account is the zero address");
        require(shares_ > 0, "Shares are 0");
        require(shares[account] == 0, "Account already has shares");

        payees.push(account);
        shares[account] = shares_;
        unchecked{
            totalShares = totalShares + shares_;
        }
    }

    /**
    Only in emergency, if something goes wrong with VRF
     */
    function revealManually() external onlyOwner {
        require(shiftIndex == 0, "Shift index is already set");
        shiftIndex = uint256(keccak256(abi.encode(blockhash(block.number),
                                                  block.coinbase,
                                                  block.difficulty,
                                                  _msgSender()
                                    ))) % MAX_NFT_SUPPLY;

        //  prevent default shift index
        if (shiftIndex == 0) {
            unchecked{
                shiftIndex = shiftIndex +  666;
            }
        }
    }

    /**
    * @dev VRF request for randomness for shift index
    */
    function requestReveal(bytes32 s_keyHash, uint s_fee) public onlyOwner returns (bytes32 requestId) {
        require(shiftIndex == 0, "Shift index is already set");
        require(IERC20(linkToken).balanceOf(address(this)) >= s_fee, "Not enough LINK to pay fee");

        // requesting randomness
        requestId = requestRandomness(s_keyHash, s_fee);
    }

    /**
    * @dev VRF reply sets shift index (abstract VRF func)
    */
    function fulfillRandomness(bytes32, uint256 randomness) internal override {
        require(shiftIndex == 0, "Shift index is already set");
        shiftIndex = randomness % MAX_NFT_SUPPLY;

        //  prevent default shift index
        if (shiftIndex == 0) {
            unchecked{
                shiftIndex = shiftIndex +  333;
            }
        }
    }

    fallback() external payable {
    }
    
    receive() external payable {
    }
}