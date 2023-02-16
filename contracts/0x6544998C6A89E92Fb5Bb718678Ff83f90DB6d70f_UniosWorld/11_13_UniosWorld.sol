// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/Base64.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "erc721a/contracts/ERC721A.sol";

import "./IRenderer.sol";

/*
                                                                    . gg,   
                                                                  =,^//KC   
                                                               ,^  ),$$`    
                                                             .`cgg^]$y      
                                 ,,,,                      /,@g$$$p~*       
                            ,[email protected]$%M%%$M$%%%[email protected]@@@@@@C][email protected]$R4L $wg$$,        
                     ,-  **^"""]%F*$$$$$F *jfg$gM5FgP$g,g%@[email protected],}|**"        
           ,l 1l,    N,        [email protected]$&&[email protected]@@@@@ggP%D$$D$]@*]@$MgL   '      
         , ' !i,$iL                  ,         ``                  ~        
       i  < .i\e$FL<|!<s!{s!'gL>,yi.i>,ilxi|ei||[email protected],grN%,,               
   ,,,., . ([email protected]&",}`.M`.;LjTL.M>.'|"/T!'7L|(,*,"]MP*CM%M`=|L,            
  |||@Kl|$W+<i,iW";T|<T!<=!<T!'Tl\s!l=ii4Lrei8($%gmpN"@[email protected]@][email protected]*TL,          
  A"'"*F*%TL T"Q,LQ,i{}i".i*,i*);G"1f"{|21T'*gz$g%$*N$M$Nr2,][email protected]\k~        
]@|     .  +`.1L`$g.|g.{T,,RLGgL$gw1g#{g|UgN$x$Lg$%m"`]`/CN#QM$&@gL>,,      
 '*4gg |<g! T!yF!aR!%!$|gL%AL{R$l&W$4MW|$gR$g&[email protected]@@|@[email protected]&&A$$g$%[email protected]!L     
   4N$g2',$l.il.$f}[email protected]@MM&@[email protected]&$,L$g$%@[email protected]@[email protected]}$$$K$&$g$%gL`.L    
            `   ygR1g$$)$$g$E%N$}l$Q&[email protected][email protected]$g$1l&$%%[email protected]$$WM"`'L      
               ilk$$($'[email protected]*4$*@$][email protected][email protected][email protected]@G)[email protected]@[&%[email protected]@$g[)@&+          
            ,!.|T[[email protected]$Qg$$g&B(iEA$%[email protected]@T%$g][email protected][email protected]@[email protected]        
          ,|<gl\}$%i$%s&gA|Tk$gg$gg$g$MY!URlE}A$k$Lgi%}M%[email protected]@$L       
      ,,;'"1L,1{$QF$$g&1.'  '"}[email protected][email protected][email protected]+    '"'"  ""[email protected][email protected][email protected]@@L       
 +,|"<+6 TL}g$Ug!U4AfA:'`    '"[email protected]$%@$g             |h$%g&%g$%[email protected]@@@       
 $'(l&ki*hM&"i&hi*" `         |[email protected]$&[email protected]             '[email protected]&ET$*%@@@$       
  }}@g"1g]1gL""     | ||    |,,[email protected]@@@$g-              A"|@[email protected]@$}$F '[email protected][email protected]      
                         !')@&$B$%g$`  |'''''''' .Qgh$%&$g&@@P`  : *BC      
                                    `            '"`""'"```` `      `     
*/
contract UniosWorld is ERC721A, ERC2981, Ownable, Pausable {
    uint256 public constant MAX_SUPPLY = 3333;

    bool public genesisAirdropped = false;
    bool public reborn = false;
    bool public alMint = false;

    uint256 public genesisAllocationPer = 1;
    uint256 public genesisTotalAllocation;
    address[] private _genesisWallets;

    uint256 public maxPerWallet = 3;
    uint256 public price = 0.02 ether;

    string public contractURIString;

    address private _rendererAddress;
    address private _rebirthAddress;

    bytes32 private _merkleRoot;

    constructor() ERC721A("Unios World", "UW") {
        _pause();
    }

    modifier mintCompliance(uint256 _amount) {
        require(totalSupply() + _amount <= publicSupply());
        require(_amount <= maxPerWallet);
        require(
            balanceOf(msg.sender) + _amount <= maxPerWallet,
            "Max mint limit"
        );
        _;
    }

    function mintAL(uint256 _amount, bytes32[] calldata _merkleProof)
        external
        payable
        mintCompliance(_amount)
    {
        require(alMint);
        require(
            MerkleProof.verify(
                _merkleProof,
                _merkleRoot,
                keccak256(abi.encodePacked(msg.sender))
            ));

        checkValue(price * _amount);
        _safeMint(msg.sender, _amount);
    }

    function mint(uint256 _amount)
        external
        payable
        whenNotPaused
        mintCompliance(_amount)
    {
        checkValue(price * _amount);
        _safeMint(msg.sender, _amount);
    }

    function rebirth(uint256 id) external {
        require(reborn);
        require(msg.sender == _rebirthAddress);

        _burn(id, true);
    }

    //////// Public View functions

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(_exists(tokenId));

        return
            _rendererAddress != address(0)
                ? IRenderer(_rendererAddress).tokenURI(tokenId)
                : "";
    }

    function contractURI() public view returns (string memory) {
        return (
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    contractURIString
                )
            )
        );
    }

    function isAllowlisted(address _address, bytes32[] calldata _merkleProof)
        public
        view
        returns (bool)
    {
        return
            MerkleProof.verify(
                _merkleProof,
                _merkleRoot,
                keccak256(abi.encodePacked(_address))
            );
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721A, ERC2981)
        returns (bool)
    {
        // Supports the following `interfaceId`s:
        // - IERC165: 0x01ffc9a7
        // - IERC721: 0x80ac58cd
        // - IERC721Metadata: 0x5b5e139f
        // - IERC2981: 0x2a55205a
        return
            ERC721A.supportsInterface(interfaceId) ||
            ERC2981.supportsInterface(interfaceId);
    }

    // Cherry-picking from ERC71AQueryable
    function tokensOfOwner(address owner)
        external
        view
        virtual
        returns (uint256[] memory)
    {
        uint256 tokenIdsLength = balanceOf(owner);
        uint256[] memory tokenIds;
        assembly {
            tokenIds := mload(0x40)
            mstore(0x40, add(tokenIds, shl(5, add(tokenIdsLength, 1))))
            mstore(tokenIds, tokenIdsLength)
        }
        address currOwnershipAddr;
        uint256 tokenIdsIdx;
        for (uint256 i = _startTokenId(); tokenIdsIdx != tokenIdsLength; ) {
            TokenOwnership memory ownership = _ownershipAt(i);
            assembly {
                // if `ownership.burned == false`.
                if iszero(mload(add(ownership, 0x40))) {
                    if mload(ownership) {
                        currOwnershipAddr := mload(ownership)
                    }
                    if iszero(shl(96, xor(currOwnershipAddr, owner))) {
                        tokenIdsIdx := add(tokenIdsIdx, 1)
                        mstore(add(tokenIds, shl(5, tokenIdsIdx)), i)
                    }
                }
                i := add(i, 1)
            }
        }
        return tokenIds;
    }

    function publicSupply() public view returns (uint256) {
        return MAX_SUPPLY - genesisTotalAllocation;
    }

    //////// Internal functions

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    //////// Private functions

    function checkValue(uint256 value) private {
        if (msg.value > value) {
            (bool succ, ) = payable(msg.sender).call{
                value: (msg.value - value)
            }("");
            require(succ);
        } else if (msg.value < value) {
            revert();
        }
    }

    //////// Airdrop functions

    function mintGenesis() external onlyOwner {
        require(!genesisAirdropped);

        for (uint256 i = 0; i < _genesisWallets.length; i++) {
            _mint(_genesisWallets[i], genesisAllocationPer);
        }

        // Locks airdrop from happening again, can only happen once
        genesisAirdropped = true;
    }

    function setGenesisWallets(
        address[] memory _addresses,
        uint256 _genesisAllocationPer
    ) external onlyOwner {
        // Store allocation for public mint purposes
        genesisTotalAllocation = _addresses.length * _genesisAllocationPer;
        genesisAllocationPer = _genesisAllocationPer;
        _genesisWallets = _addresses;
    }

    //////// Admin functions

    function mintTo(address to, uint256 _amount) external onlyOwner {
        require(totalSupply() + _amount <= publicSupply());

        _mint(to, _amount);
    }

    function setContractURI(string memory _contractURI) external onlyOwner {
        contractURIString = _contractURI;
    }

    function setRoyaltyInfo(address receiver, uint96 feeNumerator)
        external
        onlyOwner
    {
        _setDefaultRoyalty(receiver, feeNumerator);
    }
    
    function setRendererAddress(address rendererAddress) external onlyOwner {
        require(rendererAddress != address(0));
        _rendererAddress = rendererAddress;
    }

    function setRebirthAddress(address rebirthAddress) external onlyOwner {
        require(rebirthAddress != address(0));
        _rebirthAddress = rebirthAddress;
    }

    function setMaxPerWallet(uint256 _maxPerWallet) external onlyOwner {
        maxPerWallet = _maxPerWallet;
    }

    function setPrice(uint256 _price) external onlyOwner {
        price = _price;
    }

    function setReborn(bool _reborn) external onlyOwner {
        reborn = _reborn;
    }

    function setALMint(bool _alMint) external onlyOwner {
        if(alMint && !_alMint){
            // AL mint turning off, turn on public
            _unpause();
        }

        alMint = _alMint;
    }

    function setMerkleRoot(bytes32 merkleRoot) external onlyOwner {
        _merkleRoot = merkleRoot;
    }

    function togglePause() external onlyOwner {
        paused() ? _unpause() : _pause();
    }

    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        (bool succ, ) = payable(msg.sender).call{value: balance}("");
        require(succ);
    }
}

//[email protected]_ved