// SPDX-License-Identifier: MIT
/*
 * KasbeerStorage.sol
 *
 * Author: Jack Kasbeer
 * Created: August 21, 2021
 */

pragma solidity >=0.5.16 <0.9.0;

import "@openzeppelin/contracts/utils/Counters.sol";

//@title A storage contract for relevant data
//@author Jack Kasbeer (@jcksber, @satoshigoat)
contract KasbeerStorage {

	//@dev These take care of token id incrementing
	using Counters for Counters.Counter;
	Counters.Counter internal _tokenIds;

	uint256 constant public royaltyFeeBps = 1500; // 15%
    bytes4 internal constant _INTERFACE_ID_ERC165 = 0x01ffc9a7;
    bytes4 internal constant _INTERFACE_ID_ERC721 = 0x80ac58cd;
    bytes4 internal constant _INTERFACE_ID_ERC721_METADATA = 0x5b5e139f;
    bytes4 internal constant _INTERFACE_ID_ERC721_ENUMERABLE = 0x780e9d63;
    bytes4 internal constant _INTERFACE_ID_EIP2981 = 0x2a55205a;
    bytes4 internal constant _INTERFACE_ID_ROYALTIES = 0xcad96cca;

	//@dev Important numbers
	uint constant NUM_ASSETS = 8;
	uint constant MAX_NUM_TOKENS = 888;
	uint constant TOKEN_WEI_PRICE = 88800000000000000;//0.0888 ETH

	//@dev Properties
	string internal contractUri;
	address public payoutAddress;

	//@dev Initial production hashes
	//Our list of IPFS hashes for each of the "Nomad" 8 Plugs (varying juice levels)
	string [NUM_ASSETS] normHashes = ["QmZzB15bPgTqyHzULMFK1jNdbbDGVGCX4PJNbyGGMqLCjL",
									  "QmeXZGeywxRRDK5mSBHNVnUzGv7Kv2ATfLHydPfT5LpbZr",
									  "QmYTf2HE8XycQD9uXshiVtXqNedS83WycJvS2SpWAPfx5b",
									  "QmYXjEkeio2nbMqy3DA7z2LwYFDyq1itbzdujGSoCsFwpN",
									  "QmWmvRqpT59QU9rDT28fiKgK6g8vUjRD2TSSeeBPr9aBNm",
									  "QmWtMb73QgSgkL7mY8PQEt6tgufMovXWF8ecurp2RD7X6R",
									  "Qmbd4uEwtPBfw1XASkgPijqhZDL2nZcRwPbueYaETuAfGt",
									  "QmayAeQafrWUHV3xb8DnXTGLn97xnh7X2Z957Ss9AtfkAD"];
	//Our list of IPFS hashes for each of the "Chicago" 8 Plugs (varying juice levels)
	string [NUM_ASSETS] chiHashes = ["QmNsSUji2wX4E8xmv8vynmSUCACPdCh7NznVSGMQ3hwLC3",
									 "QmYPq4zFLyREaZsPwZzXB3w94JVYdgFHGgRAuM6CK6PMes",
									 "QmbrATHXTkiyNijkfQcEMGT7ujpunsoLNTaupMYW922jp3",
									 "QmWaj5VHcBXgAQnct88tbthVmv1ecX7ft2aGGqMAt4N52p",
									 "QmTyFgbJXX2vUCZSjraKubXfE4NVr4nVrKtg3GK4ysscDX",
									 "QmQxQoAe47CUXtGY9NTA6dRgTJuDtM4HDqz9kW2UK1VHtU",
									 "QmaXYexRBrbr6Uv89cGyWXWCbyaoQDhy3hHJuktSTWFXtJ",
									 "QmeSQdMYLECcSfCSkMenPYuNL2v42YQEEA4HJiP36Zn7Z6"];
	//Our list of IPFS hashes for each of the "Chicago" 8 Plugs (varying juice levels)
	string [NUM_ASSETS] stlHashes = ["QmcB5AqhpNA8o5RT3VTeDsqNBn6VGEaXzeTKuomakTNueM",
									 "QmcjP9d54RcmPXgGt6XxNavr7dtQDAhAnatKjJ5a1Bqbmc",
									 "QmV3uFvGgGQdN4Ub81LWVnp3qjwMpKDvVwQmBzBNzAjWxB",
									 "Qmc3fWuQTxAgsBYK2g4z5VrK47nvfCrWHFNa5zA8DDoUbs",
									 "QmWRPStH4RRMrFzAJcTs2znP7hbVctbLHPUvEn9vXWSTfk",
									 "QmVobnLvtSvgrWssFyWAPCUQFvKsonRMYMYRQPsPSaQHTK",
									 "QmQvGuuRgKxqTcAA7xhGdZ5u2EzDKvWGYb1dMXz2ECwyZi",
									 "QmdurJn1GYVz1DcNgqbMTqnCKKFxpjsFuhoS7bnfBp2YGk"];
}