# @version 0.3.7

# @title STORMDRAIN
# @notice contract that accepts DRIP DROP tokens as a bidding token, and the winner receives a 1/1 artwork
# @author transientlabs.xyz
# @license MIT

"""
                                           .*((((####(/.                                           
                                  .((/%(%/*/*#/(*&#%/*//%/#((#(%##,                                 
                             /(#/**((*/////(/((((#(*/##///(((#(#(/(###%#                            
                         (((/#*/**/##*****#(*//(/////(#////(##(#(###((((####                        
                     .%(*/#(/////#/.            *//%             (/*/##(#(##%%#                     
                   ##*////(((#///*/##*/*//#////#*(///(#/////#(/((#(((##(#((((##%#%                  
                ,#///*//*///((/,*,,(/*****//////(///////(//(((((((((/(((///(##(#(###*               
              *#////#/(/   (///                 /(/#                  (///  ,//#(%(%##(             
            .#(%/%///*%/(//((#/////(/*/*#/%**//#/(/(//(//(#/#/(((%(#((###(((#(###/#%####            
           ##((/((/,,,,,***(/////**/**//////((((((////((((((##(##((#(#(#((/*/////#####%#%%          
          ##/(((*(         /(//                 /#((                  ((((        (((#(####         
        .#%(/(/#/#//*//*#(#((/((/#///((((//(/(#(/((((((/(((((((((((#(#(##(#(#((####%######%#        
        #(((#((/,.,,,,....(((//,.        .      ((//( . . .........  (#(#/           #######%       
       #%(%(//#            (#((                 (((/,                 ((#/            #(##(#%%      
      ##//(/%//**#*%////%/#((//#*////(#/////%(((/#(%/(//%/(/(((#/((((##(///(%((###(#(##(%#####&     
      ##%(#(/              (##(                 ((((*                .###/              #####%#     
     (#&%((/(              ((#(.                /(((/                ./(((  ....,,,*****((#####/    
     ((((/%/#///*%/#///*#/(////(/(/(/(////#/#((((%##/(//#(#/(//#/#(((#(((##(##(((##############%    
     ##%%%#(.              (%(/              (/(((#*/(//             .###/              (##& #%%    
     (###(//(///////////////((((//////////////(((((##(((//(///////(//(/((((((((((############%#%    
     (#%(/((#/#////#/%(///#/%//*/#*#////#/#///(((#((((((((((#((/(#(%(####(#(#(#################,    
      ##(##((              ##(#                 (###                  #(((              ##%#%#%     
      ###((((((//((((/((((#/#(((##((((/##//(//#%(((((##(/(//##(//((((##((((((((#(######((####%#     
       ##((##/#(//##(/(//##(((//(#////(##/((//##(/(((#((((((###(((((#####(#################%#%      
        #%#(#(#%           (###                 #%((                  #(((           /(######       
         #%####(((##(#(((#((####((/((#((((((#(#((((#(#((((%((((((%##(#((######(%####(#######        
          %###(#((((((#((((/#((/**/////*////////((((#///(/(((((((((((#####*,**,,,*###(####%         
           #######%(.      ,(##                 ((((                  ####       ##(####%/          
             %%###(((%/#(/((#(#(((/%(#((((%(#((#(#(#(#(#%(#((#####((###(###(##(####(%###            
               #%####((((  .((##                 (((,                 #(#*  #(#######%              
                 %###((#(((((((#                /((((                /##((((######%#                
                   #####(#((#(#(#((((%(#((((#(#((#(#(#((((#(#(((##(##(#((###(####/                  
                      %##%(##(#(#(((            .#(#(           .(((((#(%(#####                     
                         ,#####(((((((((((((((#((((((##(((((##(((((##(((###                         
                              ####(#(((##(((((#((((#((((((((###(#(####(                             
                                   .###%####%####%%(######%####%(
"""

### interfaces ###
interface ERC165:
    def supportsInterface(interface_id: bytes4) -> bool: nonpayable

interface ERC721:
    def isApprovedForAll(owner: address, operator: address) -> bool: nonpayable
    def safeTransferFrom(_from: address, _to: address, token_id: uint256, data: Bytes[1024]): nonpayable
    def transferFrom(_from: address, _to: address, token_id: uint256): nonpayable

interface IERC721Receiver:
    def onERC721Received(operator: address, from_: address, token_id: uint256, data: Bytes[1024]) -> bytes4: nonpayable

implements: ERC165
implements: IERC721Receiver

### events ###
event OwnershipTransferred:
    previous_owner: indexed(address)
    new_owner: indexed(address)

event PrizeEscrowed:
    prev_owner: indexed(address)
    contract: indexed(address)
    token_id: indexed(uint256)

event PrizeReturned:
    time: indexed(uint256)

event AuctionStarted:
    start_time: indexed(uint256)
    duration: indexed(uint256)

event Bid:
    bidder: indexed(address)
    amount: indexed(uint256)
    auction_end_time: indexed(uint256)

event AuctionSettled:
    winner: indexed(address)
    winning_amount: indexed(uint256)

### interface ids ###
ERC165_INTERFACE_ID: constant(bytes4) = 0x01ffc9a7
ERC173_INTERFACE_ID: constant(bytes4) = 0x7f5828d0
ERC721_RECEIVER_INTERFACE_ID: constant(bytes4) = 0x150b7a02

### state variables ###
owner: public(address) # owner of the contract for access control
total_drips_bid: public(uint256) # a count of all drips bid - auction can only be started this is 0
highest_bidder: public(address) # current higher bid account address
highest_bid: public(uint256) # current highest bid number
prize_contract: public(ERC721) # contract address for the 1 of 1 art work
prize_token_id: public(uint256) # token id for the 1 of 1 art work
stormdrain_address: public(address) # address to which the winning drips are sent and from which the prize token is sent
DRIP_DROP_CONTRACT: immutable(ERC721) # drip drop contract address on mainnet
auction_started: public(bool)
auction_end_time: public(uint256)
_received_tokens: HashMap[address, HashMap[uint256, address]] # hashmap from ERC721 contract address and token id to previous owner
_bid_tokens: HashMap[address, DynArray[uint256, 1024]] # hashmap from bidder account address to dynamic array of drip drop token ids

### external state-changing functions ###
@external
def __init__(drip_drop_contract: address):
    # @notice constructor that sets the owner of the contract and the drip drop contract address
    self.owner = msg.sender
    DRIP_DROP_CONTRACT = ERC721(drip_drop_contract)

    log OwnershipTransferred(empty(address), msg.sender)

@external
def transferOwnership(new_owner: address):
    # @notice function to transfer ownership to a new account
    # @dev can only be called by the current owner
    # @dev be VERY careful when calling this as it cannot be undone
    # @dev can set the new owner to the zero address to renounce ownership
    assert msg.sender == self.owner, "Only the owner can call this function"

    previous_owner: address = self.owner
    self.owner = new_owner

    log OwnershipTransferred(previous_owner, new_owner)

@external
def onERC721Received(operator: address, from_: address, token_id: uint256, data: Bytes[1024]) -> bytes4:
    # @notice function to receive NFTs directly
    # @dev these NFTs don't count towards the bid in any way
    # @dev it is NOT recommended that NFTs are sent directly to the contract
    self._received_tokens[msg.sender][token_id] = from_
    return method_id("onERC721Received(address,address,uint256,bytes)", output_type=bytes4)

@external
def escrow_prize(prize_owner: address, contract_address: address, token_id: uint256):
    # @notice function to escrow the prize
    # @dev can only be called by the current owner
    # @dev can only be called if there is not a current prize contract set
    assert msg.sender == self.owner, "Only the owner can call this function"
    assert self.prize_contract.address == empty(address), "Prize already escrowed"

    self.prize_contract = ERC721(contract_address)
    self.prize_token_id = token_id
    self.stormdrain_address = prize_owner

    self.prize_contract.safeTransferFrom(prize_owner, self, token_id, b"")
    
    log PrizeEscrowed(prize_owner, contract_address, token_id)

@external
def return_prize():
    # @notice function to return prize to the stormdrain address
    # @dev can only be called by the current owner
    # @dev can only be called if there is a prize contract set
    # @dev can only be called if the auction has not started or was canceled
    assert msg.sender == self.owner, "Only the owner can call this function"
    assert self.prize_contract.address != empty(address), "No prize escrowed yet"
    assert not self.auction_started, "Auction started, can't return escrowed prize"

    self.prize_contract.safeTransferFrom(self, self.stormdrain_address, self.prize_token_id, b"")
    self._received_tokens[self.prize_contract.address][self.prize_token_id] = empty(address)

    self.prize_contract = empty(ERC721)
    self.prize_token_id = 0
    self.stormdrain_address = empty(address)

    log PrizeReturned(block.timestamp)

@external
def start_auction(duration: uint256):
    # @notice function to start the auction and set a duration
    # @dev duration is in seconds
    # @dev can only be called by the current owner
    # @dev can only be called if there is a prize contract set
    assert msg.sender == self.owner, "Only the owner can call this function"
    assert self.prize_contract.address != empty(address), "No prize escrowed yet"
    assert self.total_drips_bid == 0, "Drips locked in contract that don't count for bids"

    self.auction_started = True
    self.auction_end_time = block.timestamp + duration

    log AuctionStarted(block.timestamp, block.timestamp + duration)

@external
def settle_auction():
    # @notice function to settle the auction
    # @dev can only be called by the current owner
    # @dev can only settle if the auction was started and the current block timestamp is past the end timestamp
    # @dev transfers drips to the stormdrain address and prize to winning address
    assert msg.sender == self.owner, "Only the owner can call this function"
    assert self.auction_started and block.timestamp > self.auction_end_time, "Auction not started or finished - cannot call yet"

    if self.highest_bid > 0:

        winning_tokens: DynArray[uint256, 1024] = self._bid_tokens[self.highest_bidder]
        for token in winning_tokens:
            DRIP_DROP_CONTRACT.safeTransferFrom(self, self.stormdrain_address, token, b"")
            self._received_tokens[DRIP_DROP_CONTRACT.address][token] = empty(address)
        self._bid_tokens[self.highest_bidder] = empty(DynArray[uint256, 1024])

        self.prize_contract.safeTransferFrom(self, self.highest_bidder, self.prize_token_id, b"")
        self._received_tokens[self.prize_contract.address][self.prize_token_id] = empty(address)

        self.prize_contract = empty(ERC721)
        self.prize_token_id = 0
        self.stormdrain_address = empty(address)

        log AuctionSettled(self.highest_bidder, self.highest_bid)

        self.total_drips_bid -= self.highest_bid
        self.highest_bidder = empty(address)
        self.highest_bid = 0

    self.auction_started = False

@external
def bid(drips: DynArray[uint256, 1024]):
    # @notice function to bid drips
    # @dev requires number bid to be greater than the current highest bid
    # @dev requires auction to be started and less than the end timestamp
    # @dev requires this contract to be approved for all on the drip drop contract
    # @dev lengthens the auction by 15 minutes if a bid comes in the final 5 minutes
    assert self.auction_started and block.timestamp <= self.auction_end_time, "Auction not in progress"
    tokens: DynArray[uint256, 1024] = self._bid_tokens[msg.sender]
    bid: uint256 = len(tokens) + len(drips)
    assert bid > self.highest_bid, "Cannot bid less than or equal to the current highest bid"
    assert DRIP_DROP_CONTRACT.isApprovedForAll(msg.sender, self), "Must approve contract for all tokens on DRIP DROP"

    for drip in drips:
        DRIP_DROP_CONTRACT.safeTransferFrom(msg.sender, self, drip, b"")
        self._bid_tokens[msg.sender].append(drip)

    self.highest_bid = bid
    self.highest_bidder = msg.sender
    self.total_drips_bid += len(drips)

    if self.auction_end_time - block.timestamp <= 300:
        self.auction_end_time = block.timestamp + 300

    log Bid(msg.sender, bid, self.auction_end_time)

@external
@nonreentrant("lock")
def retrieve_drips():
    # @notice function to retrieve drips after the auction has been settled
    # @dev requires auction to be settled
    # @dev requires number of tokens escrowed as bid to be 1 or greater for msg.sender
    assert not self.auction_started, "Auction still on going"
    tokens: DynArray[uint256, 1024] = self._bid_tokens[msg.sender]
    assert len(tokens) > 0, "No tokens to return"

    for token in tokens:
        DRIP_DROP_CONTRACT.safeTransferFrom(self, msg.sender, token, b"")
        self._received_tokens[DRIP_DROP_CONTRACT.address][token] = empty(address)
    self._bid_tokens[msg.sender] = empty(DynArray[uint256, 1024])

    self.total_drips_bid -= len(tokens)

@external
@nonreentrant("lock")
def retrieve_direct_transfer_nft(contract_address: address, token_id: uint256):
    # @notice function to retrieve nft's transfered directly to the contract
    # @dev contract address and token_id cannot be drips bid or the prize token
    # @dev msg.sender must be the previous owner of the token they are trying to retrieve
    if contract_address == DRIP_DROP_CONTRACT.address:
        assert token_id not in self._bid_tokens[msg.sender], "Token you are trying to retrieve is escrowed as a bid"
    elif contract_address == self.prize_contract.address:
        assert token_id != self.prize_token_id, "Token you are trying to retrieve is the prize token"
    else:
        assert self._received_tokens[contract_address][token_id] == msg.sender, "You were not the previous owner of the token you are trying to retrieve"

    ERC721(contract_address).safeTransferFrom(self, msg.sender, token_id, b"")
    self._received_tokens[contract_address][token_id] = empty(address)

@external
def flush_drips(user: address):
    # @notice function to flush drips out of the contract for a specific user
    # @dev this is a backup function just in case people aren't paying attention or anything like that
    # @dev uses `transferFrom` instead of `safeTransferFrom` so that there is no risk of reentrancy...
    #      this shouldn't be an issue as the bidders were able to hold drips prior
    assert msg.sender == self.owner, "Only the owner can call this function"
    assert not self.auction_started, "Auction still on going"
    tokens: DynArray[uint256, 1024] = self._bid_tokens[user]
    assert len(tokens) > 0, "No tokens to return"

    for token in tokens:
        DRIP_DROP_CONTRACT.transferFrom(self, user, token)
        self._received_tokens[DRIP_DROP_CONTRACT.address][token] = empty(address)
    self._bid_tokens[user] = empty(DynArray[uint256, 1024])

    self.total_drips_bid -= len(tokens)

### external view/pure functions ###
@view
@external
def get_drips_bid(bidder: address) -> DynArray[uint256, 1024]:
    #@notice returns list of drips bid for bidder
    return self._bid_tokens[bidder]

@view
@external
def drip_drop_contract() -> address:
    return DRIP_DROP_CONTRACT.address
@view
@external
def get_number_drips_bid(bidder: address) -> uint256:
    # @notice returns number of bids for bidder
    return len(self._bid_tokens[bidder])

@view
@external
def supportsInterface(interface_id: bytes4) -> bool:
    # @notice function to support ERC-165 interface lookups
    # @dev returns true if supported and interface_id is not 0xffffffff
    return (
        interface_id in [ERC165_INTERFACE_ID, ERC173_INTERFACE_ID, ERC721_RECEIVER_INTERFACE_ID] and
        interface_id != 0xffffffff
    )