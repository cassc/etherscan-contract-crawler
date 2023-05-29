//SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

/// @title Stardust Generation
/// @author Techchelle llc, Stardust7, Inc ᖭི༏ᖫྀ
/// @notice Stardust Society: Stardust Society Genesis, Stardust x Kendra Scott, Spreading Stardust, Stardust Generation (current) 
/// @notice commercial rights only, permitted for Stardust Generation, more info @ stardustsociety.io

import "erc721a/contracts/extensions/ERC721AQueryable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

//    .-'''-.,---------.   ____   .-------.    ______      ___    _   .-'''-.,---------.                         
//   / _     \          \.'  __ `.|  _ _   \  |    _ `''..'   |  | | / _     \          \                        
//  (`' )/`--'`--.  ,---/   '  \  | ( ' )  |  | _ | ) _  |   .'  | |(`' )/`--'`--.  ,---'                        
// (_ o _).      |   \  |___|  /  |(_ o _) /  |( ''_'  ) .'  '_  | (_ o _).      |   \                (`' )    __/\__    (`' )           
//  (_,_). '.    :_ _:     _.-`   | (_,_).' __| . (_) `. '   ( \.-.|(_,_). '.    :_ _:               (_ o _)   \    /   (_ o _)             
// .---.  \  :   (_I_)  .'   _    |  |\ \  |  |(_    ._) ' (`. _` /.---.  \  :   (_I_)                (_,_)    / /\ \    (_,_)           
// \    `-'  |  (_(=)_) |  _( )_  |  | \ `'   |  (_.\.' /| (_ (_) _\    `-'  |  (_(=)_)                          
//  \       /    (_I_)  \ (_ o _) |  |  \    /|       .'  \ /  . \ /\       /    (_I_)                           
//   `-...-'     '---'   '.(_,_).'''-'   `'-' '-----'`     ``-'`-''  `-...-'     '---'                           
//   .-_'''-.      .-''-. ,---.   .--.   .-''-. .-------.      ____  ,---------..-./`)    ,-----.   ,---.   .--. 
//  '_( )_   \   .'_ _   \|    \  |  | .'_ _   \|  _ _   \   .'  __ `\          \ .-.') .'  .-,  '. |    \  |  | 
// |(_ o _)|  ' / ( ` )   |  ,  \ |  |/ ( ` )   | ( ' )  |  /   '  \  `--.  ,---/ `-' \/ ,-.|  \ _ \|  ,  \ |  | 
// . (_,_)/___|. (_ o _)  |  |\_ \|  . (_ o _)  |(_ o _) /  |___|  /  |  |   \   `-'`";  \  '_ /  | |  |\_ \|  | 
// |  |  .-----|  (_,_)___|  _( )_\  |  (_,_)___| (_,_).' __   _.-`   |  :_ _:   .---.|  _`,/ \ _/  |  _( )_\  | 
// '  \  '-   .'  \   .---| (_ o _)  '  \   .---|  |\ \  |  .'   _    |  (_I_)   |   |: (  '\_/ \   | (_ o _)  | 
//  \  `-'`   | \  `-'    |  (_,_)\  |\  `-'    |  | \ `'   |  _( )_  | (_(=)_)  |   | \ `"/  \  ) /|  (_,_)\  | 
//   \        /  \       /|  |    |  | \       /|  |  \    /\ (_ o _) /  (_I_)   |   |  '. \_/``".' |  |    |  | 
//    `'-...-'    `'-..-' '--'    '--'  `'-..-' ''-'   `'-'  '.(_,_).'   '---'   '---'    '-----'   '--'    '--'

/// @dev ERC721AQueryable extension of ERC721A for querying ownership
contract StardustGeneration is ERC721AQueryable, Ownable {

    // contract variables 
    using Strings for uint256;
    using Address for address;
    address public ms;
    string public metaSuffix; 
    string public baseTokenURI;
    bytes32 public merkleRoot; // for starlist and reservelist                              

    // minting phase and wallet limit
    uint16 public constant MAX_STARLIST = 7;
    uint16 public constant MAX_RESERVELIST = 7;
    uint16 public maxPublic = 7; 
    uint16 public maxTotalPerWallet = 14;

    // supply and cost 
    uint256 public constant MAX_SUPPLY = 7777; 
    uint256 public cost = 0.04 ether;
    
    // toggle minting phases
    bool public starlistOpen = false;
    bool public reservelistOpen = false;
    bool public publicOpen = false;
    bool public isRevealed = false; 
  
    // check to see if spots have already been minted                                      ᖭི༏ᖫྀ
    mapping(address => uint256) private starlistRedeemed; 
    mapping(address => uint256) private reservelistRedeemed;

    /// @dev emit events                                                         ᖭི༏ᖫྀ
    event Withdraw(address indexed to, uint256 amount);
    event StardustAirdrop(uint256 totalSent); 
    
    constructor( 
            string memory _name, 
            string memory _symbol,
            string memory _initBaseTokenURI,
            string memory _metaSuffix,
            bytes32 _merkleRoot,
            address[] memory _withdrawAddress)
            ERC721A(_name, _symbol)
        {
            baseTokenURI = _initBaseTokenURI; 
            metaSuffix = _metaSuffix; 
            merkleRoot = _merkleRoot; 
            setWithdrawAddress(_withdrawAddress);
        }
    
    // set metasuffix function
    function setMetaSuffix(string calldata _newSuffix) external onlyOwner {
        metaSuffix = _newSuffix;
    }

    // token uri
    function setBaseTokenURI(string calldata _baseTokenURI) external onlyOwner { 
      baseTokenURI = _baseTokenURI; 
    }
    // token uri                                                                
    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override(ERC721A,IERC721A)
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for a nonexistent token"
        );

        if (isRevealed == true) {
            return bytes(baseTokenURI).length > 0 ? string(abi.encodePacked(baseTokenURI, tokenId.toString(), metaSuffix)) : "";
        } else {
            return bytes(baseTokenURI).length > 0 ? string(abi.encodePacked(baseTokenURI, "prereveal", metaSuffix)) : "";
        }
    }
    /// @dev more efficient to start at 1, see ERC721A
    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    /// @dev set merkle root for starlist and reservelist
    function setMerkleRoot(bytes32 _root) external onlyOwner {
        merkleRoot = _root;
    }

    // set cost function
    function setCost(uint256 _newCost) external onlyOwner {
        cost = _newCost;
    }

    // set max mints allowed for public 
    function setMaxPublic(uint16 _amount) external onlyOwner {
        maxPublic = _amount;
    }
    // set max mints allowed per wallet  
    function setMaxTotalPerWallet(uint16 _amount) external onlyOwner {
        maxTotalPerWallet = _amount;
    }
//                                                                                                                     ᖭི༏ᖫྀ
//                                                                                                                        
//                                                                                                                            (_I_)
//                                                                                                                           (_(=)_)
//                                                                                                                            (_I_)

    // toggle phases
    function togglePhase(uint256 _mintingPhase) external onlyOwner {
        if ( _mintingPhase == 1 ) {
            starlistOpen = true;  
        } else if ( _mintingPhase == 2 ) {
            starlistOpen = false; 
            reservelistOpen = true; 
        } else if ( _mintingPhase == 3 ) {
            reservelistOpen = false; 
            publicOpen = true; 
        } else {
            publicOpen = false; 
        }
    }
    // toggle reveal
    function toggleReveal(string calldata _revealedMetadataURI) external onlyOwner {
        isRevealed = true; 
        baseTokenURI = _revealedMetadataURI;
    }
    // toggle pause
    function togglePause() external onlyOwner {
        starlistOpen = false; 
        reservelistOpen = false; 
        publicOpen = false; 
    }

    // safely mint each nft to the caller/receiver 
    function _mintLoop(address _receiver, uint256 _mintAmount) internal {
        _safeMint(_receiver, _mintAmount);
    }

    // Generate the leaf node (the hash of tokenID concatenated with the account address)
    function _leaf(address account) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(account));
    }

    // Merkle Proof Verification
    function _verifyMerkleList(
        bytes32 _leafNode,
        bytes32[] memory _merkleProof
    ) internal view returns (bool) {
        return MerkleProof.verify(_merkleProof, merkleRoot, _leafNode);
    } 

    /// @notice starlist mint 
    function mintStarlist(
        bytes32[] calldata _merkleProof,
        uint256 _mintAmount
    ) external payable {
        require(starlistOpen == true, "The starlist not open");
        require(
            _verifyMerkleList(_leaf(msg.sender), _merkleProof),
            "Invalid proof"
        );
        unchecked {
            require(_mintAmount > 0, "Your mint amount should be greater than 0");
            require(
                (starlistRedeemed[msg.sender] + _mintAmount) <= MAX_STARLIST,
                "Your mint amount exceeds the max mint per starlist"
            );
            require(totalSupply() + _mintAmount <= MAX_SUPPLY,
                "You would exceed the max supply of tokens"
            );
            require(
                msg.value == (cost * _mintAmount),
                "Insuffient funds"
            );
            starlistRedeemed[msg.sender] += _mintAmount;
            _mintLoop(msg.sender, _mintAmount);
        }
    }

    /// @notice reservelist mint
    function mintReservelist(                                                                                       
        bytes32[] calldata _merkleProof,
        uint256 _mintAmount
    ) external payable {
        require(reservelistOpen == true, "The reservelist mint is not open");
        require(
            _verifyMerkleList(_leaf(msg.sender), _merkleProof),
            "Invalid proof"
        );
        unchecked {
            require(_mintAmount > 0, "Your mint amount should be greater than 0");
            require(
                (reservelistRedeemed[msg.sender] + _mintAmount) <= MAX_RESERVELIST,
                "Your mint amount exceeds the max mint per reservelist"
            );
            require(totalSupply() + _mintAmount <= MAX_SUPPLY,
                "You would exceed the max supply of tokens"
            );
            require(
                msg.value == (cost * _mintAmount),
                "Insuffient funds"
            );
            reservelistRedeemed[msg.sender] += _mintAmount;
            _mintLoop(msg.sender, _mintAmount);
        }
    }

    /// @notice public mint                                                                                                  ᖭི༏ᖫྀ
    function mintPublic(uint256 _mintAmount) 
        external payable  
    {
        /** @dev utilizing _numberMinted versus balanceOf                                          ᖭི༏ᖫྀ  (_I_)
                 balanceOf is # of nfts you have at time of t(x)                                      (_(=)_)
                 w/balanceOf users can transfer them out to mint more                                  (_I_)  ᖭི༏ᖫྀ
        */
        uint256 ownerTokenCount = _numberMinted(msg.sender); 
        require(starlistOpen == false, "Starlist is open");
        require(reservelistOpen == false, "Reservelist is open");
        require(publicOpen == true, "Public sale is not open");
        unchecked {
            require(_mintAmount > 0, "Your mint amount should be greater than 0");
            require(
                _mintAmount <= maxPublic,
                "Your mint amount exceeds the max mint per public sale"
            );
            require(
                totalSupply() + _mintAmount <= MAX_SUPPLY,
                "Exceeds Max Supply"
            );
            require(
                (ownerTokenCount + _mintAmount) <= maxTotalPerWallet,
                "Sorry, you cant mint more, it exceeds the per wallet total"
            );
            require(
                msg.value == (cost * _mintAmount), 
                "Insufficient funds"
            );
            _mintLoop(msg.sender, _mintAmount);
        }
    }

    // ✦ ˑ ִֶָ 𓂃⊹  airdrop ✦ ˑ ִֶָ 𓂃⊹ 
    function airdrop(address[] calldata _airdropAddresses, uint256 _mintAmount) external onlyOwner {
        uint256 totalSent = (_airdropAddresses.length * _mintAmount);
        unchecked {
            for (uint256 i = 0; i < _airdropAddresses.length; i++) {
                address to = _airdropAddresses[i];
                require(
                    (_airdropAddresses.length * _mintAmount) + totalSupply() <= MAX_SUPPLY,
                    "Airdropping this many would exceed the max supply"
                );
                _mintLoop(to, _mintAmount);
            }
        }
        emit StardustAirdrop(totalSent);
    }

    // ✦ ˑ ִֶָ 𓂃⊹ withdraw stardust `✦ ˑ ִֶָ 𓂃⊹ ⊹ 
    function setWithdrawAddress(address[] memory newAddress) public onlyOwner {
        /// @dev multisig
        ms = newAddress[0]; 
    }

    function withdrawStardust() external onlyOwner {
        uint256 amount = address(this).balance;
        require(amount <= address(this).balance);
        require(amount >= 0, "No funds available");
        Address.sendValue(payable(ms), amount);
        emit Withdraw(ms, amount);
    }
}