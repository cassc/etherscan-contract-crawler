/*
    SPDX-License-Identifier: MIT


                                    .....              ..::^^::..                             
                          .:~!7777??777!~^:   .^~77?????????77!~:.                        
                       :~7?????77777777?????77????777777777777????!^.                     
                    .~7??7777777777777777777??77777777777777777777???~.                   
                  .~??77777777????777777777777777777777???????7777777??~                  
                 ^??777777???777777??7777777777777777??7~~~~!7???777777?7:                
                !?777777??!^.      .~777777777777777?!.       .:!??77777??^               
               7?77777??~.           :?77777777777777            .!?77777??^              
              :!!7??7?!.             :?77777777777777^:.           :7???7!~~.             
      .:~!!!!!~^^:^!?~           :~!7?777777777777777???7~.         .77^::^~!!7!!~^.      
    :!777777777777~::         :!???????777777777777????????7:        .:~777777777777!:    
   !7777777777777777~       ^7??7!~~~~~7??777777?77!~~~!!7???7:      ^7777777777777777!.  
  !777777777777777777!    :7??~^!J5PGPY!^!?777?7~^7J5P5Y7~^!???!    ~7777777777777777777. 
 ~77777777777777777777^  ~??!:7G########G^^?7?!:JB########5~^7??7. :77777777777777777777! 
 !77777777777777777777! ~??^^G############!:?!.G############Y:!??7 ~777777777777777777777 
 !77777777777777777777~.??^:###############:~.5##############G.!??.^777777777777777777777 
 ^77777777777777777777.^?! :?P#############5 ~##############P? .7?~.77777777777777777777^ 
  ~777777777777777777^.7?.^~BJ7YG##########B ?###########GJ7JY:^^??::777777777777777777~  
   ^777777777777777!.:7?7.P:&&&J .~?5PGGGP5! .YGBBBBG5?~.^G#&J!J.?7?..!777777777777777^   
     ^!7777777777~:  !??!.B:G&&7      7555P#~YG55YY.     .&&&^5Y.?7?.  :~7777777777!^     
       ..:^^^^:.     ~?77.G~J#PY:    .5Y?7!~.^!7?YG~     7B&#:#!^?7?.     .:^^^^:.        
                     ~?7?^^Y.75GBBBY..::^^^^^^^^^:::.?GGGPY7^~G.777?.                     
                     :?77?:^7#####G ^~~^^^^^^^^^^~~~^.P#####!?:~?777                      
                      7777?~~YB###B~.:^^^~~~~~~~^^^:.^B####B?:!?77?~                      
                      ^?77??~.^B####P?~^:::::::::^~75#####7.^??77?7.                      
                       !??~^7PB########BBGP555PGGB########B5!^!???:                       
                        !:!B######G555P###########BGGB#######P!^7^                        
                         ~#######7.:&&?.?5PBBBG5!?PGG::7B######Y                          
                          ~B####B.^^!?^ J5J~.7JGY:YJ7:~:^#####5.                          
                            !G###5::.JP#~.J! 7P! !J?.~~.!###5:                            
                              ^JG#B?^5GGJ~5J~JP!.#&P.^^JBP!.                              
                                 :!YPPGGB#####BGP55J?J?~.                                 
                                      .^~77??J??7~^..       
                                      

    Limited-edition drops exclusive to LILKOOL supporters and collectors.
    
    KOOL to Collect brought to you by Special Delivery.           
*/

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Burnable.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/security/PullPayment.sol";

// Placeholder name
contract KOOLToCollect is
    ERC1155,
    ERC1155Burnable,
    ERC1155Supply,
    ERC2981,
    AccessControl,
    PullPayment
{
    using Counters for Counters.Counter;
    using ECDSA for bytes32;

    // Token ids for various editions
    Counters.Counter private _tokenIds;

    // Mint prices for various editions
    mapping(uint256 => uint256) public mintPrice;

    // Limit for how many items can be minted
    mapping(uint256 => uint256) public numberMinted;
    mapping(uint256 => uint256) public maxMints;

    // Track whether an address already minted
    mapping(uint256 => mapping(address => bool)) private _hasMinted;

    // Address that is allowed to sign signatures to verify user minting
    address public signer;

    // Address that should recieve payments and royalties
    address public paymentRecipient;

    // Set royalty to 10% (1000 basis points)
    uint96 public constant ROYALTY_BASIS_POINTS = 1000;

    // Role that is allowed to create new editions
    bytes32 public constant CREATOR_ROLE = keccak256("CREATOR_ROLE");

    string private _contractURI;

    constructor(address newSigner)
        ERC1155(
            "https://spacelooters.nyc3.digitaloceanspaces.com/metadata/{id}.json"
        )
    {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(CREATOR_ROLE, msg.sender);

        setContractURI(
            "https://spacelooters.nyc3.digitaloceanspaces.com/metadata/contract.json"
        );
        setPaymentRecipient(msg.sender);
        setSigner(newSigner);
    }

    function setContractURI(string memory newContractURI) public {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender));
        _contractURI = newContractURI;
    }

    /**
        Returns the URI for the contract-level metadata. 
        
        See https://docs.opensea.io/docs/contract-level-metadata for more information.

        @return The URI for the contract-level metadata.
     */
    function contractURI() public view returns (string memory) {
        return _contractURI;
    }

    function setURI(string memory newURI) public {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender));
        _setURI(newURI);
    }

    /**
        Change address of payment recipient.

        @param newPaymentRecipient Address of new payment recipient
     */
    function setPaymentRecipient(address newPaymentRecipient) public {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender));
        require(
            newPaymentRecipient != address(0) &&
                newPaymentRecipient != paymentRecipient
        );

        paymentRecipient = newPaymentRecipient;
        _setDefaultRoyalty(newPaymentRecipient, ROYALTY_BASIS_POINTS);
    }

    /**
        Sets a new signer to use for verifying off-chain signatures for minting.

        @param newSigner Address of the new signer.
     */
    function setSigner(address newSigner) public {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender));
        require(newSigner != signer && newSigner != address(0));
        signer = newSigner;
    }

    /**
        Add a new edition to the collection.

        @param mintPrice_ The cost (in wei) to mint an item.
        @param maxMints_ The maximum number of items that may be minted.

        @return tokenId - The id of the new token.
     */
    function newEdition(uint256 mintPrice_, uint256 maxMints_)
        public
        returns (uint256 tokenId)
    {
        require(hasRole(CREATOR_ROLE, msg.sender));
        _tokenIds.increment();
        tokenId = _tokenIds.current();
        mintPrice[tokenId] = mintPrice_;
        maxMints[tokenId] = maxMints_;
    }

    /**
        Check whether the address has minted the item.

        @param address_ The address to check if it has minted.
        @param tokenId The id of the token.

        @return A boolean indicating whether the address has minted this token.
     */
    function hasMinted(address address_, uint256 tokenId)
        public
        view
        returns (bool)
    {
        return _hasMinted[tokenId][address_];
    }

    /**
        Mint an item of one of the editions in the collection.

        @param tokenId The id of the token in the collection.
        @param expirationTimestamp The expiration Unix timestamp (in seconds) of the signature.
        @param signature An Ethereum signed message hash required to mint.
     */
    function mint(
        uint256 tokenId,
        uint32 expirationTimestamp,
        bytes memory signature
    ) public payable {
        // Check the signature is valid
        require(
            _verify(tokenId, expirationTimestamp, signature),
            "Spacelooters: invalid signature"
        );
        // Check the signature has not expired
        require(
            block.timestamp <= expirationTimestamp,
            "Spacelooters: signature has expired"
        );
        // Check that the sender has not minted this item before
        require(
            !hasMinted(msg.sender, tokenId),
            "Spacelooters: sender has already minted"
        );
        // Check the maximum number of mints for this item has not been reached
        require(
            numberMinted[tokenId] < maxMints[tokenId],
            "Spacelooters: mint supply limit of token has been reached"
        );
        // Check the correct amount of wei has been sent
        require(
            msg.value == mintPrice[tokenId],
            "Spacelooters: not enough ETH sent"
        );

        _hasMinted[tokenId][msg.sender] = true;
        numberMinted[tokenId]++;

        _mint(msg.sender, tokenId, 1, "");
        _asyncTransfer(paymentRecipient, msg.value);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(AccessControl, ERC1155, ERC2981)
        returns (bool)
    {
        return
            AccessControl.supportsInterface(interfaceId) ||
            ERC1155.supportsInterface(interfaceId) ||
            ERC2981.supportsInterface(interfaceId);
    }

    /**
        Verify the `signature` was signed by the `signer` address.

        The signature is generated as (in pseudocode):
        
        signer.sign(
            keccak256(abi.encodePacked(
                "\x19Ethereum Signed Message:\n32",
                keccak256(abi.encodePacked(
                    msg.sender,
                    tokenId,
                    expirationTimestamp,
                    address(this)
                ))
            ))
        )

        @param tokenId The token id the signature is for.
        @param expirationTimestamp The expiration Unix timestamp (in seconds) for the signature.
        @param signature An Ethereum signed message hash. 

        @return A boolean indicating whether the signature has been verified.
     */
    function _verify(
        uint256 tokenId,
        uint32 expirationTimestamp,
        bytes memory signature
    ) internal view returns (bool) {
        return
            keccak256(
                abi.encodePacked(
                    msg.sender,
                    tokenId,
                    expirationTimestamp,
                    address(this)
                )
            ).toEthSignedMessageHash().recover(signature) == signer;
    }

    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal override(ERC1155, ERC1155Supply) {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }
}