/**
 *Submitted for verification at Etherscan.io on 2023-06-21
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

//////////////////////////////////////////////////////////////////////////////////////
//         ^J7                                                                      //
//        ~?5BJ^             ^~^          ~~^  ^~^^^^^^^^^~~  ^~~^^^^^~~^^^^^~~^    //
//      ^!??YBB5~            !P?^         ?5~  757~~~~~~~!Y?  ^YJ~~~~~YY~~~~~?Y~    //
//     ^7???YBBBG!            7^!~        ^7   ^7                     ~!            //
//    ~???JYP#BBBB?          ^7  ~!~      ^7   ^7                     ~!            //
//  ^7Y5PGGBB&&&###5^        ^7^  ^!!^    ^7   !Y~^^^^^^^~7!          ~!            //
//  ^7JPGBBBB&&&&B5J~        ^7^    ^!~^  ^7   7Y~~~~~~~~~?7          ~!            //
//   ^!!!7YPB#PJ??J!^        ^7^      ~!~ ^7   ^7                     ~!            //
//    ^!?7!!7?J5G5~           7        ^!!~7   ^7                     ~!            //
//      ~7J?YGBG?            !P!         ^J5~  75!~~~~~~~!J7          JY^           //
//       ^!?YBY~             ^!^          ~~^  ~!~^^^^^^^^!~          !!^           //
//         ^?7                                                                      //
//////////////////////////////////////////////////////////////////////////////////////
//   Author: 0xInuarashi                                                            //
//////////////////////////////////////////////////////////////////////////////////////

/**
 *  Notes:
 *      From what it looks like, the maximum data size is around 900 KB - 1000 KB per TX
 *      taking note as 30M gas limit
 * 
 *      Using string data is slightly cheaper than bytes
 * 
 *      Referred data can be used through a chain of Data(id, null, null) lookups
 * 
 *      Scoped searching can be done using a Data(null,identifier,creator) filter     
 */

contract ETHNET {

    /**
     * MAPPING for ETHNET ID Generation
     *      nonce is used to create predictable and pre-calculatable
     *      hashes based on a keccak256(nonce, msg.sender) which is useful
     *      for indexer cross-checking and more.
     *      
     *      It is also used to generate unique data IDs which can be used
     *      to reference the data in the future.
     */
    mapping(address => uint256) public nonce;

    /**
     * EVENT for ETHNET Data Submission
     * 
     * params:
     *      id - bytes32 hash to identify & lookup the Data entry
     *      identifier - string hash to identify & lookup the Identifier (e.g. protocol)
     *      creator - address to identify & lookup the Data creator
     */
    event Data(bytes32 indexed id, string indexed identifier, 
    address indexed creator, string data);

    /**
     * FUNCTION for ETHNET Data Submission
     *      identifier - used as a label for the data, for example, a protocol ticker
     *      data - the data attached to the transaction
     * 
     * Note:
     *      We do not have any state here. We simply create an event that can be indexed.
     *      We use msg.sender as creator here, which means multi-sig and contracts 
     *      can also submit arbritary data.
     */
    function submit(
        string calldata identifier, 
        string calldata data) 
    external returns (uint256, bytes32) {

        // Get the nonce of the msg.sender       
        uint256 _nonce = nonce[msg.sender];

        // Calculate the unique Data ID based on the nonce and msg.sender
        bytes32 _id = keccak256(abi.encodePacked(_nonce, msg.sender));
        
        // Emit the Data (Arbritary Data Storage) on the blockchain
        emit Data(_id, identifier, msg.sender, data);
        
        // Increment the nonce of the msg.sender
        unchecked { nonce[msg.sender]++; }

        // Return the initial nonce and the calculated ID for composability usage
        return (_nonce, _id);
    }
}