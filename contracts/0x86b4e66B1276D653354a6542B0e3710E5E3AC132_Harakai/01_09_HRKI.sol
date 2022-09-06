//SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./ERC721A.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./IERC721A.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract Harakai is ERC721A, Ownable {
    using SafeMath for uint256;

    error YouCannotClaimTwice();
    error NoContracts();
    error InsufficentFundsForMint();
    error MintWouldExceedAllowedForIndvidualInWhitelist();
    error InvalidAmountToBeMinted();
    error NotPrelisted();
    error MintWouldExceedMaxSupply();
    error PublicSaleInactive();
    error PreSaleInactive();

    string private _baseTokenURI =
        "ipfs://QmTRbCM1iG7sDFUaH7vHect8vb9ycfrXtX87NmYzCaLVm3/";
   
    uint256 public constant maxSupply = 777;

    bool private publicSale;
    bool private preSale;

    bytes32 private presaleMerkleRoot;

    constructor() ERC721A("Harakai!", "HARAKAI!") {
        _mint(msg.sender,50);
        _mint(0x571C18e700cfed4FA1BE6e179770e643987475E0,25);
        _mint(0x1F6EfED745836A03975aa5924B3C5bDa21262fc4,20);
        _mint(0x444481136f7f3A8a6940ff256544fe105Cd284E9,1);
        _mint(0x62F5E7837a7b4eA4A4174e78FE78f5fC029B3AeB,1);
        _mint(0x211dbD6D9c448F7727B4aDa89d0b936e6741A9B1,2);
        _mint(0xFaa4f13867665e54dE10bBd6f0B338fBc9cD8c95,1);
        _mint(0xe9fE2AA3e59E759876A1986F91f37de3b3Be8ac9,1);
        _mint(0xCAaCF9B302287837993Eb5DB055d4FF9c214fcd9,1);
        _mint(0x543EA3B6ac7b23101354fac7DB2fCc2360881c7B,1);
        _mint(0x1F7a5288C948d391A7Fc5F37fF5F0128530a3F4f,1);
        _mint(0xdB29dA6c180D5396514725FE392defFA5B77A3cA,1);
        _mint(0x01503DC708ce3C55017194847A07aCb679D49f47,1);
        _mint(0xee43B92b789a59A8855C849A84272f1933D28439,1);
        _mint(0x557a5bf27885cB528f57e287D9BBc38f9dCD6430,1);
        _mint(0x37c47fA92c1A7a65D56D6Efa5B1799cDB7100e2e,1);
        _mint(0xd0017A0044EE74D5b1D2feffBcAEFF090A9Aa6Ca,1);
        _mint(0xaEBB58C8a0dA9866Ec673397DB66c57aF880CFa2,1);
        _mint(0x55c3121077D9F33b9Ed04bc6723f2A210f8B472C,1);
        _mint(0x246774d486B946Fb8ecB123866B5e46699aBad64,1);
        _mint(0x4A822F418842bD4136807fAdB3249eEc4A6c827e,1);
        }

    modifier callerIsUser() {
        if (msg.sender != tx.origin) revert NoContracts();
        _;
    }

    function viewPerWalletLimit() external pure returns (uint8) {
        return 1;
    }

    function mint() external callerIsUser {
        uint256 ts = totalSupply();
        if (!publicSale) revert PublicSaleInactive();
        if (ts + 1 > maxSupply) revert MintWouldExceedMaxSupply();
        if (_numberMinted(msg.sender) + 1 > 1)
            revert InvalidAmountToBeMinted();

        _mint(msg.sender, 1);
    }

    function presaleMint(bytes32[] calldata _studentProof)
        external
        callerIsUser
    {
        uint256 ts = totalSupply();
        if (!preSale) revert PreSaleInactive();
        if (ts + 1 > maxSupply)
            revert MintWouldExceedMaxSupply();
        if (
            !MerkleProof.verify(
                _studentProof,
                presaleMerkleRoot,
                keccak256(abi.encodePacked(msg.sender))
            )
        ) revert NotPrelisted();
        if (_numberMinted(msg.sender) + 1 > 1)
            revert MintWouldExceedAllowedForIndvidualInWhitelist();

        _mint(msg.sender, 1);
    }

    function setPresaleMerkleRoot(bytes32 _presaleMerkleRoot)
        external
        onlyOwner
    {
        presaleMerkleRoot = _presaleMerkleRoot;
    }

    function isValid(address _user, bytes32[] calldata _studentProof)
        external
        view
        returns (bool)
    {
        return
            MerkleProof.verify(
                _studentProof,
                presaleMerkleRoot,
                keccak256(abi.encodePacked(_user))
            );

    }

     function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string calldata baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }
    
    function isPublicSaleActive() external view returns (bool) {
        return publicSale;
    }

    function isPreSaleActive() external view returns (bool) {
        return preSale;
    }

    function togglePreSaleActive() external onlyOwner {
        preSale = !preSale;
    }

    function togglePublicSaleActive() external onlyOwner {
        publicSale = !publicSale;
    }
}