//                                                                                                                                               
//  This is an ERC721 compliant smart contract for:
//   https://pix.ls
//
//  Bug Bounty:
//   Please see the details of our bug bounty program below.  
//   https://pix.ls/bug_bounty
//
//  Disclaimer:
//   We take the greatest of care when making our smart contracts but this is crypto and the future 
//   is always unknown. Even if it is exciting and full of wonderful possibilities, anything can happen,  
//   blockchains will evolve, vulnerabilities can arise, and markets can go up and down. Pix.ls and its  
//   owners accept no liability for any issues related to the use of this contract or any losses that may occur. 
//   This contract should be used for fun, art, and playing with collectables. It should not be used as an  
//   investment contract. Please see our full terms here: 
//   https://pix.ls/terms


// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;
import "./base/ERC721Tradeable.sol";

contract PixlSoV is ERC721Tradeable 
{   
    // the mint marshal authorises all mints
    // if set to 0 then minting is disabled
    address private _mintMarshal;

    // only authorized burners can burn tokens
    // this allows nft game contracts to reclaim sov tokens when when minting game tokens
    mapping (address => bool) public isBurner; 

    constructor(address _owner, address _recovery, address _treasury,address _mmarshal, address _proxyRegistry) 
        ERC721Extended(_owner, _recovery, _treasury, "https://pix.ls/meta/sov/", _proxyRegistry) 
        ERC721("Bricks", unicode"⬢Bricks")    
    {        
        // set the mint marshal
        _mintMarshal = _mmarshal;    
           
    }

    

    
    /// MINTING

    // the mint marshal will need to approve all mints
    // set to 0 to disable minting
    function setMintMarshal(address newMarshal) external onlyOwner {
        _mintMarshal = newMarshal;
    }
    
    // ERC721 standard checks:
    // can't mint while the contract is paused (checked in _beforeTokenTransfer())
    // token id's can't already exist 
    // cant mint to address(0)
    // if 'to' refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.

    event Commission(address indexed earner, uint earned, uint tokenId); 

    // mint a single token
    function mint(address to, uint256 tokenId, uint256 expiry, address commissionTo, uint256 commissionWei, address feeTo, bytes memory marshalSignature) external payable reentrancyGuard   
    {       
        // CHECKS
        // check the details match what the marshal has signed
        validMint(_msgSender(), to, tokenId, msg.value, expiry, commissionTo, commissionWei, feeTo, marshalSignature);

        // EFFECTS
        _safeMint(to, tokenId);

        // INTERACTIONS
        // handle payments
        // the amounts have already been checked in hashMintDetails()

        //   security note: calls to a receivers below should only revert if insufficient gas is sent by the minter
        //   receivers can't be smart contracts IF we get them to sign a message before being added as a receiver
        //    - currently only EOA's (externally owned accounts) can sign a message on the ethereum network
        //    - smart contracts don't have a private key and can't sign a message
        //    - this means we should get all commission receivers to sign a message before they can receive commission

        uint _paidComm = 0;
        uint _paidFee = 0;

        // only pay out comm if address provided
        if(commissionTo!=address(0)){
            _paidComm = commissionWei;

            (bool success, ) = commissionTo.call{value:_paidComm}("");    
            require(success, "pay comm failed");        

            emit Commission(commissionTo, _paidComm, tokenId); 
        }

        // if no feeTo is provided then the fee will be retained by the contract
        if(feeTo!=address(0)){            
            _paidFee = msg.value - _paidComm;

            // we could pay the whole fee as commission above, so check for 0
            if(_paidFee>0){
                (bool success, ) = feeTo.call{value:_paidFee}("");    
                require(success, "pay fee failed");    
            }
        }

        // safety check  (should never be hit)
        assert(_paidComm + _paidFee <= msg.value);
    }

    function validMint(address minter, address to, uint256 tokenId, uint256 feeWei, uint256 expiry, address commissionTo, uint256 commissionWei, address feeTo, bytes memory marshalSignature) public view returns(bool)   
    {        
        // get the mint details hash 
        bytes32 _mint_hash = hashMintDetails(minter, to, tokenId, feeWei, expiry, commissionTo, commissionWei, feeTo);

        // check the marshal signed this mint hash
        require(_mintMarshal == signerOfHash(_mint_hash, marshalSignature), "bad hash");  

        // the details and signature are valid
        return true;
    }

    // this generates a hash of a mint details that can then be signed by the mint marshal
    function hashMintDetails(address minter, address to, uint256 tokenId, uint256 feeWei, uint256 expiry, address commissionTo, uint256 commissionWei, address feeTo) public view returns (bytes32){

        // check not already minted
        require(!_exists(tokenId), "already minted");

        // if the marshal is set to 0 then minting is disabled
        require(_mintMarshal!=address(0), "minting off");

        // the mint must not be expired yet
        require(block.timestamp < expiry, "expired");

        // if we must pay commission then we must have a valid amount
        if(commissionTo!=address(0)){           
            require(feeWei>0 && commissionWei>0 && commissionWei<=feeWei, "bad comm");
            require(commissionTo!=minter, "comm self");
        } 

        // if we must pay the fee onwards then we must have a valid fee
        if(feeTo!=address(0)){           
            require(feeWei>0, "feeTo no fee");
        }  

        // nonce is not required because mint's can't be replayed due to the tokenId being used 
        // also, the expiry timestamps are likely to change between all mints

        // now return the hash
        return keccak256(abi.encode(
            minter,
            to,
            tokenId,
            feeWei,
            expiry,
            commissionTo, 
            commissionWei, 
            feeTo,
            address(this)        // including the contract address prevents cross-contract replays  
        ));
    }

    /// BURNING

    // the contract owner can burn tokens it owns
    // or an authorized burner contract can burn any token
    // the contract owner can't burn someone elses tokens
    // normal users can't burn tokens

    // ERC721 standard checks:
    // can't burn while the contract is paused (checked in _beforeTokenTransfer())
    // the token id must exist
    
    // emitted when an authorization changes
    event BurnerSet(address indexed burner, bool auth);
   
    // changes a burners authorization
    function setBurner(address burner, bool authorized) external onlyOwner 
    { 
        isBurner[burner] = authorized;        
        emit BurnerSet(burner, authorized);        
    }

    // burn a single token
    function burn(uint256 tokenId, address belongsTo) external reentrancyGuard  
    {        
        address tokenOwner = ownerOf(tokenId);
        address contractOwner = owner();

        require(belongsTo == tokenOwner, "wrong owner");
        require(isBurner[_msgSender()]==true || 
                (tokenOwner == contractOwner && contractOwner == _msgSender() ), "not authed");
        _burn(tokenId);
    }
}