// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./MKLockRegistry.sol";
import "erc721a/contracts/ERC721A.sol";

/*
                       j╫╫╫╫╫╫ ]╫╫╫╫╫H                                          
                        ```╫╫╫ ]╫╫````                                          
    ▄▄▄▄      ▄▄▄▄  ÑÑÑÑÑÑÑ╫╫╫ ]╫╫ÑÑÑÑÑÑÑH ▄▄▄▄                                 
   ▐████      ████⌐ `````````` ``````````  ████▌                                
   ▐█████▌  ▐█████⌐▐██████████ ╫█████████▌ ████▌▐████ ▐██████████ ████▌ ████▌   
   ▐██████████████⌐▐████Γ▐████ ╫███▌└████▌ ████▌ ████ ▐████│█████ ████▌ ████▌   
   ▐████▀████▀████⌐▐████ ▐████ ╫███▌ ████▌ █████████▄ ▐██████████ ████▌ ████▌   
   ▐████ ▐██▌ ████⌐▐████ ▐████ ╫███▌ ████▌ ████▌▐████ ▐████│││││└ ██████████▌   
   ▐████      ████⌐▐██████████ ╫███▌ ████▌ ████▌▐████ ▐██████████ ▀▀▀▀▀▀████▌   
    ''''      ''''  '''''''''' `'''  `'''  ''''  ''''  '''''''''` ██████████▌   
╓╓╓╓  ╓╓╓╓  ╓╓╓╓                              .╓╓╓╓               ▀▀▀▀▀▀▀▀▀▀Γ   ===
████▌ ████=▐████                              ▐████                             
████▌ ████= ▄▄▄▄ ▐█████████▌ ██████████▌▐██████████ ║█████████▌ ███████▌▄███████
█████▄███▀ ▐████ ▐████▀████▌ ████▌▀████▌▐████▀▀████ ║████▀████▌ ████▌▀████▀▀████
█████▀████⌐▐████ ▐████ ╫███▌ ████▌ ████▌▐████ ▐████ ║████ ████▌ ████▌ ████=▐████
████▌ ████=▐████ ▐████ ╫███▌ █████▄████▌▐████ ▐████ ║████ ████▌ ████▌ ████=▐████
████▌ ████=▐████ ▐████ ╫███▌ ▀▀▀▀▀▀████▌▐██████████ ║█████████▌ ████▌ ████=▐████
▀▀▀▀` ▀▀▀▀  └└└└ `▀▀▀▀ "▀▀▀╘ ▄▄▄▄▄▄████▌ ▀▀▀▀▀▀▀▀▀▀ `▀▀▀▀▀▀▀▀▀└ ▀▀▀▀` ▀▀▀▀  ▀▀▀▀
                             ▀▀▀▀▀▀▀▀▀▀U                                      
*/

contract MonkeyLegends is MKLockRegistry, ERC721A {
    uint256 public constant MAX_SUPPLY = 10000;
    uint256 public constant NUM_RESERVED = 11;

    address public authSigner;
    uint256 public mintPrice = 0.3 ether;

    function setMintPrice(uint256 _price) external onlyOwner {
        mintPrice = _price;
    }

    event AuthSignerSet(address indexed newSigner);

    constructor(address _erc20Token, address _authSigner)
        ERC721A("Monkey Legends", "MKL")
    {
        peach = IERC20(_erc20Token);
        authSigner = _authSigner;
        baseURI = "https://meta.monkeykingdom.io/3/";
        super._safeMint(_msgSender(), NUM_RESERVED);
    }

    // set auth signer
    function setAuthSigner(address _authSigner) external onlyOwner {
        authSigner = _authSigner;
        emit AuthSignerSet(_authSigner);
    }

    // breeding
    uint256 public constant MAX_BREED = 4442;
    uint256 public numBreeded = 0;
    mapping(string => uint256) public wukongsBreedCount;
    mapping(string => uint256) public baepesBreedCount;
    mapping(string => bool) public peachUsed;

    function breed(string[] calldata hashes, bytes calldata sig) external {
        uint256 numToMint = hashes.length / 3;
        require(numBreeded + numToMint <= MAX_BREED, "MAX_BREED reached");
        require(hashes.length % 3 == 1, "Invalid call");
        bytes memory b = abi.encode(hashes, _msgSender());
        require(recoverSigner(keccak256(b), sig) == authSigner, "Invalid sig");
        unchecked {
            for (uint256 n = 0; n < 3 * numToMint; ) {
                string memory mkHash = hashes[n++];
                string memory dbHash = hashes[n++];
                string memory peachHash = hashes[n++];
                require(
                    wukongsBreedCount[mkHash]++ < 2 &&
                        baepesBreedCount[dbHash]++ < 2 &&
                        !peachUsed[peachHash],
                    "Check breeding quota"
                );
                peachUsed[peachHash] = true;
            }
        }
        super._safeMint(_msgSender(), numToMint);
        numBreeded += numToMint;
    }

    // whitelist
    uint256 public constant MAX_WHITELIST_MINT = 4000;
    uint256 public numMinted;
    mapping(uint256 => mapping(address => bool)) public whitelistClaimed;
    uint256 public currentWhitelistTier = 1;

    function setCurrentWhitelistTier(uint256 tier) external onlyOwner {
        require(tier > currentWhitelistTier, "tier can only go up");
        currentWhitelistTier = tier;
    }

    function mint(uint256 tier, bytes calldata sig) external payable {
        unchecked {
            require(
                numMinted + 1 <= MAX_WHITELIST_MINT,
                "Whitelist mint finished"
            );
            require(tier == currentWhitelistTier, "Invalid tier");
            bytes memory b = abi.encodePacked(tier, _msgSender());
            require(
                recoverSigner(keccak256(b), sig) == authSigner,
                "Invalid sig"
            );
            require(
                whitelistClaimed[currentWhitelistTier][_msgSender()] == false,
                "Whitelist quota used"
            );
            whitelistClaimed[currentWhitelistTier][_msgSender()] = true;
            require(msg.value >= mintPrice, "Insufficient ETH");
        }
        super._safeMint(_msgSender(), 1);
        numMinted++;
    }

    // claim
    IERC20 public peach;
    uint256 public claimPrice = 0;
    uint256 public MAX_CLAIMABLE = 1558;
    uint256 public numClaimed = 0;

    function setClaimPrice(uint256 _claimPrice) external onlyOwner {
        claimPrice = _claimPrice;
    }

    function claim(uint256 n) external {
        require(claimPrice > 0, "Claiming not open");
        require(numClaimed + n <= MAX_CLAIMABLE, "All claim quota gone.");
        peach.transferFrom(_msgSender(), address(this), claimPrice * n);
        super._safeMint(_msgSender(), n);
        numClaimed += n;
    }

    // withdraw
    function withdrawAll() external onlyOwner {
        payable(_msgSender()).transfer(address(this).balance);
        peach.transferFrom(
            address(this),
            _msgSender(),
            peach.balanceOf(address(this))
        );
    }

    function recoverERC20(address tokenAddress) external onlyOwner {
        IERC20 token = IERC20(tokenAddress);
        token.transfer(owner(), token.balanceOf(address(this)));
    }

    // locking
    function _beforeTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal view override(ERC721A) {
        require(isUnlocked(startTokenId), "Token locked");
    }

    // metadata
    string public baseURI;

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string memory newURI) public onlyOwner {
        baseURI = newURI;
    }

    // crypto
    function splitSignature(bytes memory sig)
        internal
        pure
        returns (
            uint8,
            bytes32,
            bytes32
        )
    {
        require(sig.length == 65, "invalid sig");

        bytes32 r;
        bytes32 s;
        uint8 v;

        assembly {
            r := mload(add(sig, 32))
            s := mload(add(sig, 64))
            v := byte(0, mload(add(sig, 96)))
        }

        return (v, r, s);
    }

    function recoverSigner(bytes32 message, bytes memory sig)
        internal
        pure
        returns (address)
    {
        uint8 v;
        bytes32 r;
        bytes32 s;

        (v, r, s) = splitSignature(sig);
        return ecrecover(message, v, r, s);
    }
}