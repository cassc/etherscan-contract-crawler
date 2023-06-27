// SPDX-License-Identifier: MIT

pragma solidity 0.8.8;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "./ERC721A.sol";

//-----------------------------------------------------------------------------------------------------
// ___    ___                                                                                     
// |\  \  /  /|                                                                                    
// \ \  \/  / /                                                                                    
//  \ \    / /                                                                                     
//   /     \/                                                                                      
//  /  /\   \                                                                                      
// /__/ /\ __\                                                                                     
// |__|/ \|__|                                                                                     
                                                                                                                                                                                          
//  _____ ______   ________  ________   ________  _________  _______   ________  ________          
// |\   _ \  _   \|\   __  \|\   ___  \|\   ____\|\___   ___\\  ___ \ |\   __  \|\   ____\         
// \ \  \\\__\ \  \ \  \|\  \ \  \\ \  \ \  \___|\|___ \  \_\ \   __/|\ \  \|\  \ \  \___|_        
//  \ \  \\|__| \  \ \  \\\  \ \  \\ \  \ \_____  \   \ \  \ \ \  \_|/_\ \   _  _\ \_____  \       
//   \ \  \    \ \  \ \  \\\  \ \  \\ \  \|____|\  \   \ \  \ \ \  \_|\ \ \  \\  \\|____|\  \      
//    \ \__\    \ \__\ \_______\ \__\\ \__\____\_\  \   \ \__\ \ \_______\ \__\\ _\ ____\_\  \     
//     \|__|     \|__|\|_______|\|__| \|__|\_________\   \|__|  \|_______|\|__|\|__|\_________\    
//                                        \|_________|                             \|_________|    
                                                                                                                                                                                             
//  ________  ________  ________                                                                   
// |\   __  \|\   __  \|\   __  \                                                                  
// \ \  \|\ /\ \  \|\  \ \  \|\  \                                                                 
//  \ \   __  \ \   __  \ \   _  _\                                                                
//   \ \  \|\  \ \  \ \  \ \  \\  \|                                                               
//    \ \_______\ \__\ \__\ \__\\ _\                                                               
//     \|_______|\|__|\|__|\|__|\|__|                                                              
//
//------------------------------------------------------------------------------------------------------------                                                                              
                                                                                                
                                                                                                

contract XMB is ERC721A, Ownable {
    enum Status {
        Pending,
        EarlyBirdSale, 
        PreSale,
        PublicSale,
        Finished
    }

    Status public status;
    bytes32 public root;
    uint256 public tokensReserved;
    uint256 public PRICE;
    uint96 public royaltyNumerator;
    uint256 public immutable maxEarlybirdMint;
    uint256 public immutable maxPresaleMint;
    uint256 public immutable maxPublicMint;
    uint256 public immutable maxSupply;
    uint256 public immutable reserveAmount;
    uint256 public immutable earlybirdTotal;

    event Minted(address minter, uint256 amount);
    event StatusChanged(Status status);
    event RootChanged(bytes32 root);
    event ReservedToken(address minter, address recipient, uint256 amount);
    event BaseURIChanged(string newBaseURI);
    event PriceChanged(uint256 PRICE);

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "Contract is not allowed to mint.");
        _;
    }

    constructor(
        string memory initBaseURI,
        uint256 _maxEarlybirdMint,
        uint256 _maxPresaleMint,
        uint256 _maxPublicMint,
        uint256 _maxSupply,
        uint256 _reserveAmount,
        uint256 _earlyBirdTotal
    )
        ERC721A(
            "Bobone",
            "XMB",
            _maxPublicMint,
            _maxSupply
        )
    {
        baseURI = initBaseURI;
        maxEarlybirdMint = _maxEarlybirdMint;
        maxPresaleMint = _maxPresaleMint;
        maxPublicMint = _maxPublicMint;
        maxSupply = _maxSupply;
        reserveAmount = _reserveAmount;
        earlybirdTotal = _earlyBirdTotal;
    }

    function setPermitTransfers(bool _permit) external onlyOwner {
        permitTransfers = _permit;
    }

    function setPermitSetApprovalForAll(bool _permit) external onlyOwner {
        permitSetApprovalForAll = _permit;
    }

    function setPermitApprove(bool _permit) external onlyOwner {
        permitApprove = _permit;
    }

    function reserve(address recipient, uint256 amount) external onlyOwner {
        require(recipient != address(0), "Zero address");
        require(amount > 0, "Invalid amount");
        require(
            totalSupply() + amount <= collectionSize,
            "Max supply exceeded"
        );
        require(
            tokensReserved + amount <= reserveAmount,
            "Max reserve amount exceeded"
        );

        uint256 multiple = amount / maxBatchSize;
        for (uint256 i = 0; i < multiple; i++) {
            _safeMint(recipient, maxBatchSize);
        }
        uint256 remainder = amount % maxBatchSize;
        if (remainder != 0) {
            _safeMint(recipient, remainder);
        }
        tokensReserved += amount;
        emit ReservedToken(msg.sender, recipient, amount);
    }

    function earlybirdMint(uint256 amount, bytes32[] calldata proof)
        external
        payable
        callerIsUser
    {
        require(status == Status.EarlyBirdSale, "EarlyBirdSale is not active.");
        require(
            MerkleProof.verify(proof, root, keccak256(abi.encodePacked(msg.sender))),
            "Invalid proof."
        );
        require(
            numberMinted(msg.sender) + amount <= maxEarlybirdMint,
            "Max mint amount per wallet exceeded."
        );
        require(
            totalSupply() + amount <= earlybirdTotal,
            "Current mint limit exceeded."
        );
        require(
            totalSupply() + amount + reserveAmount - tokensReserved <=
                collectionSize,
            "Max supply exceeded."
        );

        _safeMint(msg.sender, amount);
        refundIfOver(PRICE * amount);

        emit Minted(msg.sender, amount);
    }


    function presaleMint(uint256 amount, bytes32[] calldata proof)
        external
        payable
        callerIsUser
    {
        require(status == Status.PreSale, "Presale is not active.");
        require(
            MerkleProof.verify(proof, root, keccak256(abi.encodePacked(msg.sender))),
            "Invalid proof."
        );
        require(
            numberMinted(msg.sender) + amount <= maxPresaleMint,
            "Max mint amount per wallet exceeded."
        );
        require(
            totalSupply() + amount + reserveAmount - tokensReserved <=
                collectionSize,
            "Max supply exceeded."
        );

        _safeMint(msg.sender, amount);
        refundIfOver(PRICE * amount);

        emit Minted(msg.sender, amount);
    }

    function mint(uint256 amount) external payable callerIsUser {
        require(status == Status.PublicSale, "Public sale is not active.");
        require(amount <= maxPublicMint, "Max mint amount per tx exceeded.");
        require(
            totalSupply() + amount + reserveAmount - tokensReserved <=
                collectionSize,
            "Max supply exceeded."
        );

        _safeMint(msg.sender, amount);
        refundIfOver(PRICE * amount);

        emit Minted(msg.sender, amount);
    }

    function refundIfOver(uint256 price) private {
        require(msg.value >= price, "Need to send more ETH.");
        if (msg.value > price) {
            payable(msg.sender).transfer(msg.value - price);
        }
    }

    function withdraw() external onlyOwner {
        require(status == Status.Finished, "Invalid status for withdrawn.");

        payable(owner()).transfer(address(this).balance);
    }

    /**
    * @dev For each existing tokenId, it returns the URI where metadata is stored
    * @param tokenId Token id
    */
    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        string memory uri = super.tokenURI(tokenId);
        return bytes(uri).length > 0 ? string(abi.encodePacked(uri, ".json")) : "";
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string calldata newBaseURI) external onlyOwner {
        baseURI = newBaseURI;
        emit BaseURIChanged(newBaseURI);
    }

    function setStatus(Status _status) external onlyOwner {
        status = _status;
        if (status == Status.Pending){
            PRICE = 0;
        }
        if (status == Status.EarlyBirdSale) {
            PRICE = 0;
        } 
        else if (status == Status.PreSale) {
            PRICE = 0.03 ether; 
        }
        else{
            PRICE = 0.05 ether; 
        }
        emit StatusChanged(_status);
        emit PriceChanged(PRICE);
    }

    function setRoot(bytes32 _root) external onlyOwner {
        root = _root;
        emit RootChanged(_root);
    }

    function setOwnersExplicit(uint256 quantity) external onlyOwner {
        _setOwnersExplicit(quantity);
    }

    function numberMinted(address owner) public view returns (uint256) {
        return _numberMinted(owner);
    }

    function getOwnershipData(uint256 tokenId)
        external
        view
        returns (TokenOwnership memory)
    {
        return ownershipOf(tokenId);
    }



    //// CODE for Royalties
    
    /**
     * @dev Sets the royalty information that all ids in this contract will default to.
     *
     * Requirements:
     *
     * - `receiver` cannot be the zero address.
     * - `feeNumerator` cannot be greater than the fee denominator.
     */
    function setDefaultRoyalty(address receiver, uint96 feeNumerator) external onlyOwner {
        require(feeNumerator <= 10000, "ERC2981: royalty fee exceeds 10% threshold");
        require(receiver != address(0), "ERC2981: invalid receiver");
        royaltyNumerator = feeNumerator;
        _defaultRoyaltyInfo = RoyaltyInfo(receiver, feeNumerator);
    }

    /**
     * @dev Removes default royalty information.
     */
    function deleteDefaultRoyalty() external onlyOwner {
        delete _defaultRoyaltyInfo;
    }

    /**
     * @dev Sets the royalty information for a specific token id, overriding the global default.
     *
     * Requirements:
     *
     * - `tokenId` must be already minted.
     * - `receiver` cannot be the zero address.
     * - `feeNumerator` cannot be greater than the fee denominator.
     */
    function setTokenRoyalty(
        uint256 tokenId,
        address receiver,
        uint96 feeNumerator
    ) external onlyOwner {
        require(feeNumerator <= 15000, "ERC2981: royalty fee exceeds the 15% threshold");
        require(receiver != address(0), "ERC2981: invalid parameters");

        _tokenRoyaltyInfo[tokenId] = RoyaltyInfo(receiver, feeNumerator);
    }

    /**
     * @dev Resets royalty information for the token id back to the global default.
     */
    function resetTokenRoyalty(uint256 tokenId) external onlyOwner {
        delete _tokenRoyaltyInfo[tokenId];
    }
}