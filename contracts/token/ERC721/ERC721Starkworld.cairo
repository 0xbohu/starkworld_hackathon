%lang starknet
%builtins pedersen range_check ecdsa

from starkware.cairo.common.alloc import alloc
from starkware.starknet.common.syscalls import (get_contract_address, get_caller_address)
from starkware.cairo.common.cairo_builtins import HashBuiltin, SignatureBuiltin
from starkware.cairo.common.uint256 import (
    Uint256, uint256_add, uint256_sub, uint256_le, uint256_lt, uint256_check, uint256_eq
)
from contracts.token.ERC721.ERC721_base import (
    ERC721_name,
    ERC721_symbol,
    ERC721_balanceOf,
    ERC721_ownerOf,
    ERC721_getApproved,
    ERC721_isApprovedForAll,
    ERC721_mint,
    ERC721_burn,

    ERC721_initializer,
    ERC721_approve,
    ERC721_setApprovalForAll,
    ERC721_transferFrom,
    ERC721_safeTransferFrom
)

from contracts.token.ERC721.ERC721_Metadata_base_ipfs import (
    ERC721_Metadata_initializer,
    ERC721_Metadata_tokenURI,
    ERC721_Metadata_setBaseTokenURI,
)

from contracts.token.ERC721.ERC165_base import (
    ERC165_supports_interface
)

from contracts.utils.Ownable_base import (
    Ownable_initializer,
    Ownable_only_owner,
    Ownable_get_owner,
    Ownable_transfer_ownership
)


#
# Constructor
#

@constructor
func constructor{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(name: felt, symbol: felt, owner: felt, 
    base_token_uri_len: felt, base_token_uri: felt*
    ):
    ERC721_initializer(name, symbol)
    ERC721_Metadata_initializer()
    Ownable_initializer(owner)
    ERC721_Metadata_setBaseTokenURI(base_token_uri_len, base_token_uri)
    let one_as_uint = Uint256(1,0)
    next_token_id_storage.write(one_as_uint)

    return ()
end

#
# Storage vars
#

# store the base attributes for tokens
# direct_x: 1 for East, 0 for West
# direct_y: 1 for North, 0 for South
# min_x: start coord x
# min_y: start coord y
# max_x: end coord x
# max_y: end coord y

@storage_var
func token_base_storage(token_id: Uint256) -> (res : (felt, felt,felt, felt,felt, felt)):
end

# store next token id
@storage_var
func next_token_id_storage() -> (next_token_id: Uint256):
end


# Token hash from IFPS can be more than 31 characters, so we need to split into array
@storage_var
func token_hash_index_storage(token_id: Uint256) -> (index : felt):
end

@storage_var
func token_hash_storage(token_id: Uint256, index : felt) -> (hash: felt):
end

#
# Getters
#

@view
func next_token_id{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }() -> (next_token_id: Uint256):
    let (next_token_id) = next_token_id_storage.read()
    return (next_token_id=next_token_id)
end


@view
func token_base{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(token_id: Uint256) -> (direct_x: felt, direct_y: felt, min_x: felt,min_y: felt,max_x: felt,max_y: felt):
    let (res) = token_base_storage.read(token_id)
    return (res[0],res[1],res[2],res[3],res[4],res[5])
end

@view
func getOwner{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }() -> (owner: felt):
    let (owner) = Ownable_get_owner()
    return (owner=owner)
end

@view
func supportsInterface{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(interface_id: felt) -> (success: felt):
    let (success) = ERC165_supports_interface(interface_id)
    return (success)
end

@view
func name{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }() -> (name: felt):
    let (name) = ERC721_name()
    return (name)
end

@view
func symbol{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }() -> (symbol: felt):
    let (symbol) = ERC721_symbol()
    return (symbol)
end

@view
func balanceOf{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(owner: felt) -> (balance: Uint256):
    let (balance: Uint256) = ERC721_balanceOf(owner)
    return (balance)
end

@view
func ownerOf{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(token_id: Uint256) -> (owner: felt):
    let (owner: felt) = ERC721_ownerOf(token_id)
    return (owner)
end

@view
func getApproved{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(token_id: Uint256) -> (approved: felt):
    let (approved: felt) = ERC721_getApproved(token_id)
    return (approved)
end

@view
func isApprovedForAll{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(owner: felt, operator: felt) -> (is_approved: felt):
    let (is_approved: felt) = ERC721_isApprovedForAll(owner, operator)
    return (is_approved)
end

@view
func tokenURI{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    }(token_id: Uint256) -> (token_uri_len: felt, token_uri: felt*):

    let (rev_arr) = alloc()

    let (rev_token_id,token_hash_len,token_hash) = _recur_read_token_hash_storage_internal(token_id,0,rev_arr)

   # read token hash and build tokenURI (baseUri is set by admin)

    let (token_uri_len, token_uri) = ERC721_Metadata_tokenURI(token_id,token_hash_len, token_hash)
    return (token_uri_len=token_uri_len, token_uri=token_uri)
end

#
# Externals
#

@external
func approve{
        pedersen_ptr: HashBuiltin*,
        syscall_ptr: felt*,
        range_check_ptr
    }(to: felt, token_id: Uint256):
    ERC721_approve(to, token_id)
    return ()
end

@external
func setApprovalForAll{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    }(operator: felt, approved: felt):
    ERC721_setApprovalForAll(operator, approved)
    return ()
end

@external
func transferFrom{
        pedersen_ptr: HashBuiltin*,
        syscall_ptr: felt*,
        range_check_ptr
    }(_from: felt, to: felt, token_id: Uint256):
    ERC721_transferFrom(_from, to, token_id)
    return ()
end

@external
func safeTransferFrom{
        pedersen_ptr: HashBuiltin*,
        syscall_ptr: felt*,
        range_check_ptr
    }(
        _from: felt,
        to: felt,
        token_id: Uint256,
        data_len: felt,
        data: felt*
    ):
    ERC721_safeTransferFrom(_from, to, token_id, data_len, data)
    return ()
end

@external
func setTokenURI{
        pedersen_ptr: HashBuiltin*,
        syscall_ptr: felt*,
        range_check_ptr
    }(base_token_uri_len: felt, base_token_uri: felt*):
    Ownable_only_owner()
    ERC721_Metadata_setBaseTokenURI(base_token_uri_len, base_token_uri)
    return ()
end

@external
func mint{
        pedersen_ptr: HashBuiltin*,
        syscall_ptr: felt*,
        range_check_ptr
    }()-> (token_id: Uint256):
    alloc_locals

     # get caller address
    let (sender_address) = get_caller_address()

    let (token_id) = next_token_id_storage.read()

    # # mint the token to sender
    mint_internal(sender_address,token_id)

    # increase by 1
    let one_as_uint = Uint256(1,0)
    let (next_token_id, _) = uint256_add(one_as_uint, token_id)
    next_token_id_storage.write(next_token_id)

    return (token_id)
end

@external
func initialTokenBase1{
        pedersen_ptr: HashBuiltin*,
        syscall_ptr: felt*,
        range_check_ptr
    }():
    Ownable_only_owner()
    initial_token_base_1_internal()
    return ()
end

@external
func initialTokenBase2{
        pedersen_ptr: HashBuiltin*,
        syscall_ptr: felt*,
        range_check_ptr
    }():
    Ownable_only_owner()
    initial_token_base_2_internal()
    return ()
end

@external
func initialTokenBase3{
        pedersen_ptr: HashBuiltin*,
        syscall_ptr: felt*,
        range_check_ptr
    }():
    Ownable_only_owner()
    initial_token_base_3_internal()
    return ()
end

@external
func initialTokenBase4{
        pedersen_ptr: HashBuiltin*,
        syscall_ptr: felt*,
        range_check_ptr
    }():
    Ownable_only_owner()
    initial_token_base_4_internal()
    return ()
end


@external
func updateTokenHash{
        pedersen_ptr: HashBuiltin*,
        syscall_ptr: felt*,
        range_check_ptr
    }(token_id: Uint256, token_hash_len: felt, token_hash: felt*):
    alloc_locals

     # get caller address
    let (sender_address) = get_caller_address()

    let (owner) = ERC721_ownerOf(token_id)
    assert owner = sender_address

    # write hash index storage
    token_hash_index_storage.write(token_id,token_hash_len)

    # write hash storage
    _recur_write_token_hash_storage_internal(token_id,token_hash_len,token_hash)


    return ()
end

@external
func transferOwnership{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(new_owner: felt) -> (new_owner: felt):
    # Ownership check is handled by this function
    Ownable_transfer_ownership(new_owner)
    return (new_owner=new_owner)
end


func _recur_write_token_hash_storage_internal{syscall_ptr : felt*, range_check_ptr, pedersen_ptr : HashBuiltin*}(
    token_id : Uint256, token_hash_len : felt, token_hash : felt*
) -> ():
alloc_locals

    if token_hash_len == 0:
        return ()
    end

    _recur_write_token_hash_storage_internal(token_id, token_hash_len-1, token_hash)

    token_hash_storage.write(token_id,token_hash_len, token_hash[token_hash_len-1])

    return ()
end


func _recur_read_token_hash_storage_internal{syscall_ptr : felt*, range_check_ptr, pedersen_ptr : HashBuiltin*}(
    token_id : Uint256, arr_len : felt, arr : felt*
) -> (token_id : Uint256, rev_arr_len : felt, rev_arr : felt*):
alloc_locals

    # get hash index
    let (token_hash_index) = token_hash_index_storage.read(token_id)
    let uint_index = Uint256(low=token_hash_index,high=0)
    let uint_arr_len = Uint256(low=arr_len,high=0) 
    # compare
    let(compare_result) = uint256_le(uint_index,uint_arr_len)
    if compare_result == 1:
        let (rev_arr) = alloc()
        return (token_id, arr_len, arr)
    end

    let (rev_token_id,rev_arr_len,rev_arr) = _recur_read_token_hash_storage_internal(token_id, arr_len+1, arr)
    let (token_hash) =  token_hash_storage.read(token_id,arr_len + 1)
    assert rev_arr[arr_len] = token_hash
    return (rev_token_id,rev_arr_len,rev_arr)

end


func mint_internal{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
_address:felt, _token_id : Uint256):
	ERC721_mint(_address, _token_id)
	return()
end

# initial token base stats, only called in constructor
func initial_token_base_1_internal{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}():

   token_base_storage.write(Uint256(1,0),(1,1,5,3,44,30))
   token_base_storage.write(Uint256(2,0),(1,1,8,31,42,70))
   token_base_storage.write(Uint256(3,0),(1,1,0,71,44,107))
   token_base_storage.write(Uint256(4,0),(1,1,44,0,90,30))
   token_base_storage.write(Uint256(5,0),(1,1,47,30,92,76))
   token_base_storage.write(Uint256(6,0),(1,1,46,79,93,110))
   token_base_storage.write(Uint256(7,0),(1,1,92,1,121,24))
   token_base_storage.write(Uint256(8,0),(1,1,93,24,122,52))
   token_base_storage.write(Uint256(9,0),(1,1,93,61,118,107))
   token_base_storage.write(Uint256(10,0),(1,1,1,110,40,129))
   token_base_storage.write(Uint256(11,0),(1,1,1,133,38,169))
   token_base_storage.write(Uint256(12,0),(1,1,2,191,42,217))
   token_base_storage.write(Uint256(13,0),(1,1,45,110,78,142))
   token_base_storage.write(Uint256(14,0),(1,1,42,142,78,194))
   token_base_storage.write(Uint256(15,0),(1,1,43,194,78,219))
   token_base_storage.write(Uint256(16,0),(1,1,79,115,117,150))
   token_base_storage.write(Uint256(17,0),(1,1,88,154,120,179))
   token_base_storage.write(Uint256(18,0),(1,1,97,182,120,207))
   token_base_storage.write(Uint256(19,0),(1,1,5,222,42,245))
   token_base_storage.write(Uint256(20,0),(1,1,6,247,37,273))
   token_base_storage.write(Uint256(21,0),(1,1,2,273,43,316))
   token_base_storage.write(Uint256(22,0),(1,1,47,220,73,251))
   token_base_storage.write(Uint256(23,0),(1,1,46,251,77,274))
   token_base_storage.write(Uint256(24,0),(1,1,44,277,76,307))
   token_base_storage.write(Uint256(25,0),(1,1,80,222,113,266))
   token_base_storage.write(Uint256(26,0),(1,1,83,272,121,290))
   token_base_storage.write(Uint256(27,0),(1,1,93,298,124,319))
   token_base_storage.write(Uint256(28,0),(1,1,124,7,162,42))
   token_base_storage.write(Uint256(29,0),(1,1,126,43,155,74))
   token_base_storage.write(Uint256(30,0),(1,1,128,75,166,108))
   token_base_storage.write(Uint256(31,0),(1,1,169,19,196,53))
   token_base_storage.write(Uint256(32,0),(1,1,171,57,197,84))
   token_base_storage.write(Uint256(33,0),(1,1,174,84,203,110))
   token_base_storage.write(Uint256(34,0),(1,1,204,13,229,56))
   token_base_storage.write(Uint256(35,0),(1,1,204,56,224,81))
   token_base_storage.write(Uint256(36,0),(1,1,206,82,231,115))
   token_base_storage.write(Uint256(37,0),(1,1,127,126,168,144))
   token_base_storage.write(Uint256(38,0),(1,1,123,146,157,186))
   token_base_storage.write(Uint256(39,0),(1,1,125,188,158,225))
   token_base_storage.write(Uint256(40,0),(1,1,170,116,194,170))
   token_base_storage.write(Uint256(41,0),(1,1,169,171,195,216))
   token_base_storage.write(Uint256(42,0),(1,1,167,217,193,226))
   token_base_storage.write(Uint256(43,0),(1,1,204,118,232,156))
   token_base_storage.write(Uint256(44,0),(1,1,196,160,229,186))
   token_base_storage.write(Uint256(45,0),(1,1,198,189,219,225))
   token_base_storage.write(Uint256(46,0),(1,1,124,238,155,266))
   token_base_storage.write(Uint256(47,0),(1,1,125,265,150,303))
   token_base_storage.write(Uint256(48,0),(1,1,132,304,155,321))
   token_base_storage.write(Uint256(49,0),(1,1,160,226,182,250))
   token_base_storage.write(Uint256(50,0),(1,1,157,250,186,279))
   token_base_storage.write(Uint256(51,0),(1,1,156,280,188,322))
   token_base_storage.write(Uint256(52,0),(1,1,189,226,231,251))
   token_base_storage.write(Uint256(53,0),(1,1,190,253,224,297))
   token_base_storage.write(Uint256(54,0),(1,1,189,306,232,322))
   token_base_storage.write(Uint256(55,0),(1,1,232,1,273,41))
   token_base_storage.write(Uint256(56,0),(1,1,233,45,273,79))
   token_base_storage.write(Uint256(57,0),(1,1,233,80,273,96))
   token_base_storage.write(Uint256(58,0),(1,1,276,0,297,31))
   token_base_storage.write(Uint256(59,0),(1,1,276,33,299,64))
   token_base_storage.write(Uint256(60,0),(1,1,278,65,298,102))
   token_base_storage.write(Uint256(61,0),(1,1,299,4,326,33))
   token_base_storage.write(Uint256(62,0),(1,1,303,38,327,69))
   token_base_storage.write(Uint256(63,0),(1,1,301,74,331,104))
   token_base_storage.write(Uint256(64,0),(1,1,233,104,258,136))
   token_base_storage.write(Uint256(65,0),(1,1,232,148,260,193))
   token_base_storage.write(Uint256(66,0),(1,1,234,194,256,223))
   token_base_storage.write(Uint256(67,0),(1,1,263,104,296,156))
   token_base_storage.write(Uint256(68,0),(1,1,262,164,285,192))
   token_base_storage.write(Uint256(69,0),(1,1,266,197,283,223))
   token_base_storage.write(Uint256(70,0),(1,1,296,103,326,137))
   token_base_storage.write(Uint256(71,0),(1,1,304,141,324,194))
   token_base_storage.write(Uint256(72,0),(1,1,296,195,328,218))
   token_base_storage.write(Uint256(73,0),(1,1,247,224,265,247))
   token_base_storage.write(Uint256(74,0),(1,1,234,247,263,269))
   token_base_storage.write(Uint256(75,0),(1,1,232,269,269,314))
   token_base_storage.write(Uint256(76,0),(1,1,273,224,298,246))
   token_base_storage.write(Uint256(77,0),(1,1,274,248,296,276))
   token_base_storage.write(Uint256(78,0),(1,1,273,278,298,321))
   token_base_storage.write(Uint256(79,0),(1,1,298,228,326,257))
   token_base_storage.write(Uint256(80,0),(1,1,304,258,331,297))
   token_base_storage.write(Uint256(81,0),(1,1,303,304,330,320))
   token_base_storage.write(Uint256(82,0),(1,1,3,321,20,367))
   token_base_storage.write(Uint256(83,0),(1,1,1,369,34,402))
   token_base_storage.write(Uint256(84,0),(1,1,4,402,33,436))
   token_base_storage.write(Uint256(85,0),(1,1,35,321,68,362))
   token_base_storage.write(Uint256(86,0),(1,1,36,371,72,413))
   token_base_storage.write(Uint256(87,0),(1,1,34,418,70,436))
   token_base_storage.write(Uint256(88,0),(1,1,74,321,103,352))
   token_base_storage.write(Uint256(89,0),(1,1,73,352,98,387))
   token_base_storage.write(Uint256(90,0),(1,1,81,387,102,433))
   token_base_storage.write(Uint256(91,0),(1,1,1,442,37,467))
   token_base_storage.write(Uint256(92,0),(1,1,2,477,41,511))
   token_base_storage.write(Uint256(93,0),(1,1,3,519,34,551))
   token_base_storage.write(Uint256(94,0),(1,1,44,437,69,474))
   token_base_storage.write(Uint256(95,0),(1,1,40,479,66,533))
   token_base_storage.write(Uint256(96,0),(1,1,40,534,69,552))
   token_base_storage.write(Uint256(97,0),(1,1,73,438,102,465))
   token_base_storage.write(Uint256(98,0),(1,1,73,478,102,527))
   token_base_storage.write(Uint256(99,0),(1,1,71,531,89,551))
   token_base_storage.write(Uint256(100,0),(1,1,0,553,32,572))
   token_base_storage.write(Uint256(101,0),(1,1,0,575,37,601))
   token_base_storage.write(Uint256(102,0),(1,1,0,605,32,645))
   token_base_storage.write(Uint256(103,0),(1,1,42,565,65,587))
   token_base_storage.write(Uint256(104,0),(1,1,39,589,66,617))
   token_base_storage.write(Uint256(105,0),(1,1,39,618,63,649))
   token_base_storage.write(Uint256(106,0),(1,1,67,555,101,586))
   token_base_storage.write(Uint256(107,0),(1,1,68,589,99,619))
   token_base_storage.write(Uint256(108,0),(1,1,66,623,99,651))
   token_base_storage.write(Uint256(109,0),(1,1,106,331,134,353))
   token_base_storage.write(Uint256(110,0),(1,1,103,366,139,389))
   token_base_storage.write(Uint256(111,0),(1,1,103,394,137,424))
   token_base_storage.write(Uint256(112,0),(1,1,139,323,188,357))
   token_base_storage.write(Uint256(113,0),(1,1,139,358,191,385))
   token_base_storage.write(Uint256(114,0),(1,1,139,399,183,426))
   token_base_storage.write(Uint256(115,0),(1,1,193,325,220,350))
   token_base_storage.write(Uint256(116,0),(1,1,200,349,220,371))
   token_base_storage.write(Uint256(117,0),(1,1,192,371,217,431))
   token_base_storage.write(Uint256(118,0),(1,1,102,432,145,456))
   token_base_storage.write(Uint256(119,0),(1,1,105,456,135,502))
   token_base_storage.write(Uint256(120,0),(1,1,105,515,136,532))
   token_base_storage.write(Uint256(121,0),(1,1,147,432,189,465))
   token_base_storage.write(Uint256(122,0),(1,1,149,473,190,501))
   token_base_storage.write(Uint256(123,0),(1,1,162,505,190,536))
   token_base_storage.write(Uint256(124,0),(1,1,196,433,219,460))
   token_base_storage.write(Uint256(125,0),(1,1,191,468,218,512))
   token_base_storage.write(Uint256(126,0),(1,1,202,517,220,538))
   token_base_storage.write(Uint256(127,0),(1,1,110,539,142,581))
   token_base_storage.write(Uint256(128,0),(1,1,112,582,142,630))
   token_base_storage.write(Uint256(129,0),(1,1,111,632,144,651))
   token_base_storage.write(Uint256(130,0),(1,1,152,538,190,585))
   token_base_storage.write(Uint256(131,0),(1,1,145,591,189,620))
   token_base_storage.write(Uint256(132,0),(1,1,163,621,194,645))
   token_base_storage.write(Uint256(133,0),(1,1,196,539,216,577))
   token_base_storage.write(Uint256(134,0),(1,1,194,577,220,593))
   token_base_storage.write(Uint256(135,0),(1,1,194,595,220,644))
   token_base_storage.write(Uint256(136,0),(1,1,220,323,256,342))
   token_base_storage.write(Uint256(137,0),(1,1,223,343,261,379))
   token_base_storage.write(Uint256(138,0),(1,1,224,381,259,406))
   token_base_storage.write(Uint256(139,0),(1,1,260,324,291,345))
   token_base_storage.write(Uint256(140,0),(1,1,271,346,297,378))
   token_base_storage.write(Uint256(141,0),(1,1,263,379,282,408))
   token_base_storage.write(Uint256(142,0),(1,1,297,324,327,344))
   token_base_storage.write(Uint256(143,0),(1,1,297,349,330,377))
   token_base_storage.write(Uint256(144,0),(1,1,299,379,315,409))
   token_base_storage.write(Uint256(145,0),(1,1,221,410,246,452))
   token_base_storage.write(Uint256(146,0),(1,1,227,453,248,489))
   token_base_storage.write(Uint256(147,0),(1,1,225,492,246,536))
   token_base_storage.write(Uint256(148,0),(1,1,250,417,278,455))
   token_base_storage.write(Uint256(149,0),(1,1,249,461,278,490))
   token_base_storage.write(Uint256(150,0),(1,1,258,495,278,533))
   token_base_storage.write(Uint256(151,0),(1,1,280,408,319,425))
   token_base_storage.write(Uint256(152,0),(1,1,279,426,329,464))
   token_base_storage.write(Uint256(153,0),(1,1,287,467,323,536))
   token_base_storage.write(Uint256(154,0),(1,1,226,544,254,574))
   token_base_storage.write(Uint256(155,0),(1,1,222,580,251,601))
   token_base_storage.write(Uint256(156,0),(1,1,223,605,257,650))
   token_base_storage.write(Uint256(157,0),(1,1,260,538,297,572))
   token_base_storage.write(Uint256(158,0),(1,1,267,574,299,612))
   token_base_storage.write(Uint256(159,0),(1,1,260,615,299,651))
   token_base_storage.write(Uint256(160,0),(1,1,307,539,331,563))
   token_base_storage.write(Uint256(161,0),(1,1,302,580,328,602))
   token_base_storage.write(Uint256(162,0),(1,1,303,605,322,643))
   token_base_storage.write(Uint256(163,0),(1,1,0,657,23,696))
   token_base_storage.write(Uint256(164,0),(1,1,8,709,31,736))
   token_base_storage.write(Uint256(165,0),(1,1,3,741,31,760))
   token_base_storage.write(Uint256(166,0),(1,1,31,653,77,683))
   token_base_storage.write(Uint256(167,0),(1,1,32,686,74,718))
   token_base_storage.write(Uint256(168,0),(1,1,38,723,76,765))
   token_base_storage.write(Uint256(169,0),(1,1,88,651,100,685))
   token_base_storage.write(Uint256(170,0),(1,1,80,686,102,714))
   token_base_storage.write(Uint256(171,0),(1,1,82,721,104,765))
   token_base_storage.write(Uint256(172,0),(1,1,2,767,34,805))
   token_base_storage.write(Uint256(173,0),(1,1,6,809,36,844))
   token_base_storage.write(Uint256(174,0),(1,1,1,844,34,881))
   token_base_storage.write(Uint256(175,0),(1,1,36,767,73,801))
   token_base_storage.write(Uint256(176,0),(1,1,37,804,73,844))
   token_base_storage.write(Uint256(177,0),(1,1,36,851,71,880))
   token_base_storage.write(Uint256(178,0),(1,1,78,768,102,789))
   token_base_storage.write(Uint256(179,0),(1,1,74,819,103,846))
   token_base_storage.write(Uint256(180,0),(1,1,73,855,101,881))
   token_base_storage.write(Uint256(181,0),(1,1,1,886,28,904))
   token_base_storage.write(Uint256(182,0),(1,1,0,906,25,934))
   token_base_storage.write(Uint256(183,0),(1,1,1,936,27,995))
   token_base_storage.write(Uint256(184,0),(1,1,32,883,63,906))
   token_base_storage.write(Uint256(185,0),(1,1,28,909,67,939))
   token_base_storage.write(Uint256(186,0),(1,1,28,944,65,996))
   token_base_storage.write(Uint256(187,0),(1,1,74,883,102,928))
   token_base_storage.write(Uint256(188,0),(1,1,67,928,92,960))
   token_base_storage.write(Uint256(189,0),(1,1,69,967,103,998))
   token_base_storage.write(Uint256(190,0),(1,1,110,654,137,690))
   token_base_storage.write(Uint256(191,0),(1,1,104,691,138,735))
   token_base_storage.write(Uint256(192,0),(1,1,107,737,139,762))
   token_base_storage.write(Uint256(193,0),(1,1,158,655,190,688))
   token_base_storage.write(Uint256(194,0),(1,1,156,694,190,734))
   token_base_storage.write(Uint256(195,0),(1,1,140,734,188,753))
   token_base_storage.write(Uint256(196,0),(1,1,190,662,223,696))
   token_base_storage.write(Uint256(197,0),(1,1,194,697,222,735))
   token_base_storage.write(Uint256(198,0),(1,1,193,736,221,765))
   token_base_storage.write(Uint256(199,0),(1,1,105,768,152,817))
   token_base_storage.write(Uint256(200,0),(1,1,111,821,152,846))
   
	return()
end

func initial_token_base_2_internal{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}():

   token_base_storage.write(Uint256(201,0),(1,1,122,851,156,873))
   token_base_storage.write(Uint256(202,0),(1,1,159,773,186,799))
   token_base_storage.write(Uint256(203,0),(1,1,157,800,199,830))
   token_base_storage.write(Uint256(204,0),(1,1,156,830,194,873))
   token_base_storage.write(Uint256(205,0),(1,1,201,767,221,783))
   token_base_storage.write(Uint256(206,0),(1,1,199,793,225,825))
   token_base_storage.write(Uint256(207,0),(1,1,199,834,224,870))
   token_base_storage.write(Uint256(208,0),(1,1,106,873,139,908))
   token_base_storage.write(Uint256(209,0),(1,1,107,916,139,941))
   token_base_storage.write(Uint256(210,0),(1,1,114,946,140,998))
   token_base_storage.write(Uint256(211,0),(1,1,141,878,180,918))
   token_base_storage.write(Uint256(212,0),(1,1,150,931,175,972))
   token_base_storage.write(Uint256(213,0),(1,1,141,972,175,996))
   token_base_storage.write(Uint256(214,0),(1,1,188,874,220,909))
   token_base_storage.write(Uint256(215,0),(1,1,182,909,222,955))
   token_base_storage.write(Uint256(216,0),(1,1,182,962,224,993))
   token_base_storage.write(Uint256(217,0),(1,1,225,653,260,683))
   token_base_storage.write(Uint256(218,0),(1,1,233,695,252,719))
   token_base_storage.write(Uint256(219,0),(1,1,225,720,259,756))
   token_base_storage.write(Uint256(220,0),(1,1,265,653,297,697))
   token_base_storage.write(Uint256(221,0),(1,1,268,697,289,713))
   token_base_storage.write(Uint256(222,0),(1,1,261,715,299,756))
   token_base_storage.write(Uint256(223,0),(1,1,298,658,326,688))
   token_base_storage.write(Uint256(224,0),(1,1,302,688,329,719))
   token_base_storage.write(Uint256(225,0),(1,1,306,728,331,766))
   token_base_storage.write(Uint256(226,0),(1,1,226,776,251,808))
   token_base_storage.write(Uint256(227,0),(1,1,226,809,251,849))
   token_base_storage.write(Uint256(228,0),(1,1,226,851,252,885))
   token_base_storage.write(Uint256(229,0),(1,1,252,790,287,816))
   token_base_storage.write(Uint256(230,0),(1,1,258,817,289,845))
   token_base_storage.write(Uint256(231,0),(1,1,263,847,294,885))
   token_base_storage.write(Uint256(232,0),(1,1,294,772,329,816))
   token_base_storage.write(Uint256(233,0),(1,1,298,816,322,853))
   token_base_storage.write(Uint256(234,0),(1,1,301,854,329,885))
   token_base_storage.write(Uint256(235,0),(1,1,232,885,262,914))
   token_base_storage.write(Uint256(236,0),(1,1,236,914,265,952))
   token_base_storage.write(Uint256(237,0),(1,1,230,952,260,997))
   token_base_storage.write(Uint256(238,0),(1,1,270,888,292,918))
   token_base_storage.write(Uint256(239,0),(1,1,266,922,302,967))
   token_base_storage.write(Uint256(240,0),(1,1,266,969,300,999))
   token_base_storage.write(Uint256(241,0),(1,1,304,890,328,925))
   token_base_storage.write(Uint256(242,0),(1,1,307,927,331,963))
   token_base_storage.write(Uint256(243,0),(1,1,307,963,330,998))
   token_base_storage.write(Uint256(244,0),(1,1,337,0,370,48))
   token_base_storage.write(Uint256(245,0),(1,1,332,49,371,76))
   token_base_storage.write(Uint256(246,0),(1,1,336,79,369,124))
   token_base_storage.write(Uint256(247,0),(1,1,372,3,405,28))
   token_base_storage.write(Uint256(248,0),(1,1,371,28,402,73))
   token_base_storage.write(Uint256(249,0),(1,1,373,75,402,120))
   token_base_storage.write(Uint256(250,0),(1,1,406,7,438,63))
   token_base_storage.write(Uint256(251,0),(1,1,406,70,439,91))
   token_base_storage.write(Uint256(252,0),(1,1,416,92,440,124))
   token_base_storage.write(Uint256(253,0),(1,1,331,124,353,156))
   token_base_storage.write(Uint256(254,0),(1,1,331,157,353,196))
   token_base_storage.write(Uint256(255,0),(1,1,336,198,356,221))
   token_base_storage.write(Uint256(256,0),(1,1,357,128,389,168))
   token_base_storage.write(Uint256(257,0),(1,1,359,169,402,203))
   token_base_storage.write(Uint256(258,0),(1,1,362,205,392,220))
   token_base_storage.write(Uint256(259,0),(1,1,404,126,437,148))
   token_base_storage.write(Uint256(260,0),(1,1,404,151,436,174))
   token_base_storage.write(Uint256(261,0),(1,1,405,174,423,217))
   token_base_storage.write(Uint256(262,0),(1,1,332,222,373,249))
   token_base_storage.write(Uint256(263,0),(1,1,333,253,372,286))
   token_base_storage.write(Uint256(264,0),(1,1,342,288,376,327))
   token_base_storage.write(Uint256(265,0),(1,1,376,222,410,247))
   token_base_storage.write(Uint256(266,0),(1,1,378,250,413,295))
   token_base_storage.write(Uint256(267,0),(1,1,377,297,412,326))
   token_base_storage.write(Uint256(268,0),(1,1,416,222,428,264))
   token_base_storage.write(Uint256(269,0),(1,1,415,266,440,294))
   token_base_storage.write(Uint256(270,0),(1,1,413,297,439,315))
   token_base_storage.write(Uint256(271,0),(1,1,443,4,472,35))
   token_base_storage.write(Uint256(272,0),(1,1,441,37,476,72))
   token_base_storage.write(Uint256(273,0),(1,1,442,77,478,98))
   token_base_storage.write(Uint256(274,0),(1,1,482,0,522,23))
   token_base_storage.write(Uint256(275,0),(1,1,492,35,517,60))
   token_base_storage.write(Uint256(276,0),(1,1,488,70,517,104))
   token_base_storage.write(Uint256(277,0),(1,1,524,7,547,39))
   token_base_storage.write(Uint256(278,0),(1,1,524,39,550,84))
   token_base_storage.write(Uint256(279,0),(1,1,524,91,552,106))
   token_base_storage.write(Uint256(280,0),(1,1,441,107,467,130))
   token_base_storage.write(Uint256(281,0),(1,1,442,132,475,175))
   token_base_storage.write(Uint256(282,0),(1,1,444,179,474,210))
   token_base_storage.write(Uint256(283,0),(1,1,482,107,499,134))
   token_base_storage.write(Uint256(284,0),(1,1,476,136,496,177))
   token_base_storage.write(Uint256(285,0),(1,1,482,178,501,212))
   token_base_storage.write(Uint256(286,0),(1,1,509,108,541,132))
   token_base_storage.write(Uint256(287,0),(1,1,502,138,536,180))
   token_base_storage.write(Uint256(288,0),(1,1,501,183,549,212))
   token_base_storage.write(Uint256(289,0),(1,1,443,212,480,253))
   token_base_storage.write(Uint256(290,0),(1,1,442,264,476,289))
   token_base_storage.write(Uint256(291,0),(1,1,448,289,481,328))
   token_base_storage.write(Uint256(292,0),(1,1,481,213,500,243))
   token_base_storage.write(Uint256(293,0),(1,1,482,245,502,285))
   token_base_storage.write(Uint256(294,0),(1,1,481,285,504,324))
   token_base_storage.write(Uint256(295,0),(1,1,504,212,543,252))
   token_base_storage.write(Uint256(296,0),(1,1,515,252,548,285))
   token_base_storage.write(Uint256(297,0),(1,1,504,286,550,328))
   token_base_storage.write(Uint256(298,0),(1,1,553,1,584,40))
   token_base_storage.write(Uint256(299,0),(1,1,555,43,574,83))
   token_base_storage.write(Uint256(300,0),(1,1,553,83,582,128))
   token_base_storage.write(Uint256(301,0),(1,1,586,4,616,47))
   token_base_storage.write(Uint256(302,0),(1,1,596,58,614,91))
   token_base_storage.write(Uint256(303,0),(1,1,587,99,622,139))
   token_base_storage.write(Uint256(304,0),(1,1,624,0,664,28))
   token_base_storage.write(Uint256(305,0),(1,1,623,29,658,82))
   token_base_storage.write(Uint256(306,0),(1,1,623,85,663,126))
   token_base_storage.write(Uint256(307,0),(1,1,552,139,578,169))
   token_base_storage.write(Uint256(308,0),(1,1,553,170,580,196))
   token_base_storage.write(Uint256(309,0),(1,1,557,206,585,231))
   token_base_storage.write(Uint256(310,0),(1,1,593,139,622,161))
   token_base_storage.write(Uint256(311,0),(1,1,589,161,611,208))
   token_base_storage.write(Uint256(312,0),(1,1,589,212,622,234))
   token_base_storage.write(Uint256(313,0),(1,1,624,141,661,162))
   token_base_storage.write(Uint256(314,0),(1,1,623,169,662,207))
   token_base_storage.write(Uint256(315,0),(1,1,623,212,646,234))
   token_base_storage.write(Uint256(316,0),(1,1,555,235,587,276))
   token_base_storage.write(Uint256(317,0),(1,1,551,279,586,302))
   token_base_storage.write(Uint256(318,0),(1,1,551,303,590,329))
   token_base_storage.write(Uint256(319,0),(1,1,590,235,626,263))
   token_base_storage.write(Uint256(320,0),(1,1,590,270,626,292))
   token_base_storage.write(Uint256(321,0),(1,1,590,292,628,323))
   token_base_storage.write(Uint256(322,0),(1,1,629,242,666,271))
   token_base_storage.write(Uint256(323,0),(1,1,630,274,660,290))
   token_base_storage.write(Uint256(324,0),(1,1,629,301,661,328))
   token_base_storage.write(Uint256(325,0),(1,1,332,333,364,357))
   token_base_storage.write(Uint256(326,0),(1,1,332,361,365,408))
   token_base_storage.write(Uint256(327,0),(1,1,340,410,366,456))
   token_base_storage.write(Uint256(328,0),(1,1,368,330,408,355))
   token_base_storage.write(Uint256(329,0),(1,1,375,355,403,415))
   token_base_storage.write(Uint256(330,0),(1,1,366,416,407,448))
   token_base_storage.write(Uint256(331,0),(1,1,410,334,437,384))
   token_base_storage.write(Uint256(332,0),(1,1,415,386,436,417))
   token_base_storage.write(Uint256(333,0),(1,1,410,416,433,444))
   token_base_storage.write(Uint256(334,0),(1,1,331,458,371,480))
   token_base_storage.write(Uint256(335,0),(1,1,344,480,372,524))
   token_base_storage.write(Uint256(336,0),(1,1,341,526,366,563))
   token_base_storage.write(Uint256(337,0),(1,1,372,458,407,502))
   token_base_storage.write(Uint256(338,0),(1,1,373,507,405,535))
   token_base_storage.write(Uint256(339,0),(1,1,380,535,404,562))
   token_base_storage.write(Uint256(340,0),(1,1,409,456,438,484))
   token_base_storage.write(Uint256(341,0),(1,1,414,490,437,536))
   token_base_storage.write(Uint256(342,0),(1,1,419,548,434,563))
   token_base_storage.write(Uint256(343,0),(1,1,339,566,372,588))
   token_base_storage.write(Uint256(344,0),(1,1,340,597,369,629))
   token_base_storage.write(Uint256(345,0),(1,1,339,636,373,667))
   token_base_storage.write(Uint256(346,0),(1,1,373,573,407,598))
   token_base_storage.write(Uint256(347,0),(1,1,377,603,400,642))
   token_base_storage.write(Uint256(348,0),(1,1,375,643,407,669))
   token_base_storage.write(Uint256(349,0),(1,1,408,563,433,607))
   token_base_storage.write(Uint256(350,0),(1,1,412,610,436,641))
   token_base_storage.write(Uint256(351,0),(1,1,408,641,433,665))
   token_base_storage.write(Uint256(352,0),(1,1,440,331,472,374))
   token_base_storage.write(Uint256(353,0),(1,1,441,373,470,416))
   token_base_storage.write(Uint256(354,0),(1,1,441,422,467,455))
   token_base_storage.write(Uint256(355,0),(1,1,472,337,508,382))
   token_base_storage.write(Uint256(356,0),(1,1,473,395,507,431))
   token_base_storage.write(Uint256(357,0),(1,1,471,433,504,459))
   token_base_storage.write(Uint256(358,0),(1,1,510,343,540,391))
   token_base_storage.write(Uint256(359,0),(1,1,514,391,553,412))
   token_base_storage.write(Uint256(360,0),(1,1,518,412,554,454))
   token_base_storage.write(Uint256(361,0),(1,1,445,459,466,485))
   token_base_storage.write(Uint256(362,0),(1,1,438,494,474,535))
   token_base_storage.write(Uint256(363,0),(1,1,440,540,472,572))
   token_base_storage.write(Uint256(364,0),(1,1,475,468,511,479))
   token_base_storage.write(Uint256(365,0),(1,1,494,499,515,527))
   token_base_storage.write(Uint256(366,0),(1,1,475,527,519,576))
   token_base_storage.write(Uint256(367,0),(1,1,519,467,554,488))
   token_base_storage.write(Uint256(368,0),(1,1,524,500,554,543))
   token_base_storage.write(Uint256(369,0),(1,1,530,543,554,572))
   token_base_storage.write(Uint256(370,0),(1,1,444,576,482,608))
   token_base_storage.write(Uint256(371,0),(1,1,438,609,483,633))
   token_base_storage.write(Uint256(372,0),(1,1,441,636,485,665))
   token_base_storage.write(Uint256(373,0),(1,1,486,575,512,598))
   token_base_storage.write(Uint256(374,0),(1,1,490,599,512,644))
   token_base_storage.write(Uint256(375,0),(1,1,485,644,516,662))
   token_base_storage.write(Uint256(376,0),(1,1,516,593,551,612))
   token_base_storage.write(Uint256(377,0),(1,1,519,617,556,645))
   token_base_storage.write(Uint256(378,0),(1,1,517,649,554,668))
   token_base_storage.write(Uint256(379,0),(1,1,558,332,583,366))
   token_base_storage.write(Uint256(380,0),(1,1,557,374,583,396))
   token_base_storage.write(Uint256(381,0),(1,1,558,401,582,444))
   token_base_storage.write(Uint256(382,0),(1,1,584,333,621,354))
   token_base_storage.write(Uint256(383,0),(1,1,593,355,624,399))
   token_base_storage.write(Uint256(384,0),(1,1,584,402,621,435))
   token_base_storage.write(Uint256(385,0),(1,1,625,331,664,370))
   token_base_storage.write(Uint256(386,0),(1,1,627,372,663,394))
   token_base_storage.write(Uint256(387,0),(1,1,629,396,654,440))
   token_base_storage.write(Uint256(388,0),(1,1,557,451,587,477))
   token_base_storage.write(Uint256(389,0),(1,1,557,480,582,517))
   token_base_storage.write(Uint256(390,0),(1,1,556,522,581,558))
   token_base_storage.write(Uint256(391,0),(1,1,588,452,613,499))
   token_base_storage.write(Uint256(392,0),(1,1,591,507,625,538))
   token_base_storage.write(Uint256(393,0),(1,1,590,544,621,565))
   token_base_storage.write(Uint256(394,0),(1,1,637,445,664,476))
   token_base_storage.write(Uint256(395,0),(1,1,627,486,660,521))
   token_base_storage.write(Uint256(396,0),(1,1,627,525,665,562))
   token_base_storage.write(Uint256(397,0),(1,1,561,569,581,608))
   token_base_storage.write(Uint256(398,0),(1,1,556,609,585,640))
   token_base_storage.write(Uint256(399,0),(1,1,556,640,584,665))
   token_base_storage.write(Uint256(400,0),(1,1,589,568,621,608))

	return()
end

func initial_token_base_3_internal{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}():

   token_base_storage.write(Uint256(401,0),(1,1,590,610,614,647))
   token_base_storage.write(Uint256(402,0),(1,1,586,649,616,667))
   token_base_storage.write(Uint256(403,0),(1,1,629,566,660,600))
   token_base_storage.write(Uint256(404,0),(1,1,637,601,663,636))
   token_base_storage.write(Uint256(405,0),(1,1,632,636,656,668))
   token_base_storage.write(Uint256(406,0),(1,1,334,669,363,691))
   token_base_storage.write(Uint256(407,0),(1,1,332,701,369,745))
   token_base_storage.write(Uint256(408,0),(1,1,338,756,368,786))
   token_base_storage.write(Uint256(409,0),(1,1,378,679,410,698))
   token_base_storage.write(Uint256(410,0),(1,1,373,700,410,751))
   token_base_storage.write(Uint256(411,0),(1,1,374,753,410,779))
   token_base_storage.write(Uint256(412,0),(1,1,410,672,438,702))
   token_base_storage.write(Uint256(413,0),(1,1,415,710,445,749))
   token_base_storage.write(Uint256(414,0),(1,1,415,750,448,779))
   token_base_storage.write(Uint256(415,0),(1,1,340,795,351,816))
   token_base_storage.write(Uint256(416,0),(1,1,333,820,346,848))
   token_base_storage.write(Uint256(417,0),(1,1,333,859,350,898))
   token_base_storage.write(Uint256(418,0),(1,1,351,787,404,809))
   token_base_storage.write(Uint256(419,0),(1,1,353,809,412,848))
   token_base_storage.write(Uint256(420,0),(1,1,351,851,411,899))
   token_base_storage.write(Uint256(421,0),(1,1,413,796,447,822))
   token_base_storage.write(Uint256(422,0),(1,1,415,825,448,860))
   token_base_storage.write(Uint256(423,0),(1,1,413,863,446,899))
   token_base_storage.write(Uint256(424,0),(1,1,345,911,370,950))
   token_base_storage.write(Uint256(425,0),(1,1,337,949,367,968))
   token_base_storage.write(Uint256(426,0),(1,1,334,970,364,996))
   token_base_storage.write(Uint256(427,0),(1,1,371,901,397,927))
   token_base_storage.write(Uint256(428,0),(1,1,374,934,398,976))
   token_base_storage.write(Uint256(429,0),(1,1,376,976,401,996))
   token_base_storage.write(Uint256(430,0),(1,1,406,900,446,930))
   token_base_storage.write(Uint256(431,0),(1,1,407,935,445,954))
   token_base_storage.write(Uint256(432,0),(1,1,406,957,446,992))
   token_base_storage.write(Uint256(433,0),(1,1,448,670,482,708))
   token_base_storage.write(Uint256(434,0),(1,1,452,708,487,738))
   token_base_storage.write(Uint256(435,0),(1,1,458,742,488,767))
   token_base_storage.write(Uint256(436,0),(1,1,492,673,527,717))
   token_base_storage.write(Uint256(437,0),(1,1,488,718,531,750))
   token_base_storage.write(Uint256(438,0),(1,1,493,750,529,767))
   token_base_storage.write(Uint256(439,0),(1,1,533,670,567,697))
   token_base_storage.write(Uint256(440,0),(1,1,534,697,567,742))
   token_base_storage.write(Uint256(441,0),(1,1,535,743,565,763))
   token_base_storage.write(Uint256(442,0),(1,1,450,773,487,815))
   token_base_storage.write(Uint256(443,0),(1,1,448,816,485,852))
   token_base_storage.write(Uint256(444,0),(1,1,448,853,478,883))
   token_base_storage.write(Uint256(445,0),(1,1,491,771,531,806))
   token_base_storage.write(Uint256(446,0),(1,1,488,808,529,850))
   token_base_storage.write(Uint256(447,0),(1,1,488,850,524,886))
   token_base_storage.write(Uint256(448,0),(1,1,533,774,567,820))
   token_base_storage.write(Uint256(449,0),(1,1,538,828,566,866))
   token_base_storage.write(Uint256(450,0),(1,1,531,867,565,885))
   token_base_storage.write(Uint256(451,0),(1,1,450,885,473,912))
   token_base_storage.write(Uint256(452,0),(1,1,463,928,482,968))
   token_base_storage.write(Uint256(453,0),(1,1,450,970,481,993))
   token_base_storage.write(Uint256(454,0),(1,1,483,886,531,906))
   token_base_storage.write(Uint256(455,0),(1,1,489,908,525,927))
   token_base_storage.write(Uint256(456,0),(1,1,493,935,512,990))
   token_base_storage.write(Uint256(457,0),(1,1,537,885,563,925))
   token_base_storage.write(Uint256(458,0),(1,1,539,927,566,949))
   token_base_storage.write(Uint256(459,0),(1,1,535,952,566,989))
   token_base_storage.write(Uint256(460,0),(1,1,573,673,596,700))
   token_base_storage.write(Uint256(461,0),(1,1,571,706,594,729))
   token_base_storage.write(Uint256(462,0),(1,1,571,730,597,773))
   token_base_storage.write(Uint256(463,0),(1,1,597,672,624,698))
   token_base_storage.write(Uint256(464,0),(1,1,596,701,619,727))
   token_base_storage.write(Uint256(465,0),(1,1,596,739,625,771))
   token_base_storage.write(Uint256(466,0),(1,1,625,672,663,701))
   token_base_storage.write(Uint256(467,0),(1,1,632,703,663,741))
   token_base_storage.write(Uint256(468,0),(1,1,625,742,657,768))
   token_base_storage.write(Uint256(469,0),(1,1,567,774,587,790))
   token_base_storage.write(Uint256(470,0),(1,1,572,798,588,844))
   token_base_storage.write(Uint256(471,0),(1,1,567,844,588,872))
   token_base_storage.write(Uint256(472,0),(1,1,597,773,619,816))
   token_base_storage.write(Uint256(473,0),(1,1,593,817,622,837))
   token_base_storage.write(Uint256(474,0),(1,1,587,838,622,868))
   token_base_storage.write(Uint256(475,0),(1,1,622,772,665,794))
   token_base_storage.write(Uint256(476,0),(1,1,624,794,665,830))
   token_base_storage.write(Uint256(477,0),(1,1,624,831,662,866))
   token_base_storage.write(Uint256(478,0),(1,1,567,874,611,913))
   token_base_storage.write(Uint256(479,0),(1,1,580,915,608,956))
   token_base_storage.write(Uint256(480,0),(1,1,572,957,602,998))
   token_base_storage.write(Uint256(481,0),(1,1,613,871,636,921))
   token_base_storage.write(Uint256(482,0),(1,1,618,934,636,969))
   token_base_storage.write(Uint256(483,0),(1,1,611,971,636,994))
   token_base_storage.write(Uint256(484,0),(1,1,640,872,660,908))
   token_base_storage.write(Uint256(485,0),(1,1,636,912,653,958))
   token_base_storage.write(Uint256(486,0),(1,1,637,959,656,997))
   token_base_storage.write(Uint256(487,0),(1,1,666,0,701,34))
   token_base_storage.write(Uint256(488,0),(1,1,665,36,699,66))
   token_base_storage.write(Uint256(489,0),(1,1,666,66,702,100))
   token_base_storage.write(Uint256(490,0),(1,1,702,6,733,37))
   token_base_storage.write(Uint256(491,0),(1,1,703,37,737,64))
   token_base_storage.write(Uint256(492,0),(1,1,703,69,727,99))
   token_base_storage.write(Uint256(493,0),(1,1,739,14,774,38))
   token_base_storage.write(Uint256(494,0),(1,1,738,45,772,77))
   token_base_storage.write(Uint256(495,0),(1,1,737,78,771,100))
   token_base_storage.write(Uint256(496,0),(1,1,666,106,696,140))
   token_base_storage.write(Uint256(497,0),(1,1,665,142,691,166))
   token_base_storage.write(Uint256(498,0),(1,1,665,166,696,204))
   token_base_storage.write(Uint256(499,0),(1,1,701,103,735,144))
   token_base_storage.write(Uint256(500,0),(1,1,706,147,738,184))
   token_base_storage.write(Uint256(501,0),(1,1,702,186,734,206))
   token_base_storage.write(Uint256(502,0),(1,1,740,101,773,123))
   token_base_storage.write(Uint256(503,0),(1,1,741,128,774,160))
   token_base_storage.write(Uint256(504,0),(1,1,737,163,772,204))
   token_base_storage.write(Uint256(505,0),(1,1,671,207,689,229))
   token_base_storage.write(Uint256(506,0),(1,1,665,231,697,270))
   token_base_storage.write(Uint256(507,0),(1,1,666,273,695,328))
   token_base_storage.write(Uint256(508,0),(1,1,703,206,728,248))
   token_base_storage.write(Uint256(509,0),(1,1,697,249,736,277))
   token_base_storage.write(Uint256(510,0),(1,1,703,287,733,320))
   token_base_storage.write(Uint256(511,0),(1,1,738,213,769,248))
   token_base_storage.write(Uint256(512,0),(1,1,738,262,774,308))
   token_base_storage.write(Uint256(513,0),(1,1,736,311,773,331))
   token_base_storage.write(Uint256(514,0),(1,1,796,1,814,33))
   token_base_storage.write(Uint256(515,0),(1,1,775,43,810,61))
   token_base_storage.write(Uint256(516,0),(1,1,781,61,810,106))
   token_base_storage.write(Uint256(517,0),(1,1,814,1,851,34))
   token_base_storage.write(Uint256(518,0),(1,1,816,33,854,53))
   token_base_storage.write(Uint256(519,0),(1,1,818,57,855,87))
   token_base_storage.write(Uint256(520,0),(1,1,855,0,882,41))
   token_base_storage.write(Uint256(521,0),(1,1,856,46,883,79))
   token_base_storage.write(Uint256(522,0),(1,1,857,89,878,106))
   token_base_storage.write(Uint256(523,0),(1,1,776,110,798,142))
   token_base_storage.write(Uint256(524,0),(1,1,776,143,792,190))
   token_base_storage.write(Uint256(525,0),(1,1,775,191,800,224))
   token_base_storage.write(Uint256(526,0),(1,1,800,114,839,157))
   token_base_storage.write(Uint256(527,0),(1,1,801,158,842,199))
   token_base_storage.write(Uint256(528,0),(1,1,804,200,843,225))
   token_base_storage.write(Uint256(529,0),(1,1,843,107,880,141))
   token_base_storage.write(Uint256(530,0),(1,1,844,142,878,168))
   token_base_storage.write(Uint256(531,0),(1,1,844,172,881,226))
   token_base_storage.write(Uint256(532,0),(1,1,778,228,816,250))
   token_base_storage.write(Uint256(533,0),(1,1,777,251,812,285))
   token_base_storage.write(Uint256(534,0),(1,1,776,286,811,329))
   token_base_storage.write(Uint256(535,0),(1,1,816,227,851,258))
   token_base_storage.write(Uint256(536,0),(1,1,824,261,843,282))
   token_base_storage.write(Uint256(537,0),(1,1,816,286,845,313))
   token_base_storage.write(Uint256(538,0),(1,1,854,232,883,254))
   token_base_storage.write(Uint256(539,0),(1,1,852,266,882,298))
   token_base_storage.write(Uint256(540,0),(1,1,852,298,879,330))
   token_base_storage.write(Uint256(541,0),(1,1,903,5,930,41))
   token_base_storage.write(Uint256(542,0),(1,1,886,46,928,59))
   token_base_storage.write(Uint256(543,0),(1,1,884,60,924,99))
   token_base_storage.write(Uint256(544,0),(1,1,930,0,961,54))
   token_base_storage.write(Uint256(545,0),(1,1,930,55,960,71))
   token_base_storage.write(Uint256(546,0),(1,1,937,73,961,101))
   token_base_storage.write(Uint256(547,0),(1,1,962,3,993,42))
   token_base_storage.write(Uint256(548,0),(1,1,965,64,996,82))
   token_base_storage.write(Uint256(549,0),(1,1,961,82,996,100))
   token_base_storage.write(Uint256(550,0),(1,1,891,105,928,159))
   token_base_storage.write(Uint256(551,0),(1,1,884,159,920,197))
   token_base_storage.write(Uint256(552,0),(1,1,895,202,920,230))
   token_base_storage.write(Uint256(553,0),(1,1,931,109,949,150))
   token_base_storage.write(Uint256(554,0),(1,1,931,151,959,178))
   token_base_storage.write(Uint256(555,0),(1,1,928,186,961,230))
   token_base_storage.write(Uint256(556,0),(1,1,962,102,993,158))
   token_base_storage.write(Uint256(557,0),(1,1,964,162,990,206))
   token_base_storage.write(Uint256(558,0),(1,1,965,207,997,230))
   token_base_storage.write(Uint256(559,0),(1,1,886,237,922,258))
   token_base_storage.write(Uint256(560,0),(1,1,883,263,922,288))
   token_base_storage.write(Uint256(561,0),(1,1,886,292,923,329))
   token_base_storage.write(Uint256(562,0),(1,1,926,230,952,258))
   token_base_storage.write(Uint256(563,0),(1,1,925,259,958,286))
   token_base_storage.write(Uint256(564,0),(1,1,923,287,959,318))
   token_base_storage.write(Uint256(565,0),(1,1,963,238,992,281))
   token_base_storage.write(Uint256(566,0),(1,1,970,282,992,300))
   token_base_storage.write(Uint256(567,0),(1,1,960,300,996,325))
   token_base_storage.write(Uint256(568,0),(1,1,666,331,691,366))
   token_base_storage.write(Uint256(569,0),(1,1,667,367,688,400))
   token_base_storage.write(Uint256(570,0),(1,1,666,417,690,450))
   token_base_storage.write(Uint256(571,0),(1,1,707,333,737,386))
   token_base_storage.write(Uint256(572,0),(1,1,696,388,731,409))
   token_base_storage.write(Uint256(573,0),(1,1,700,417,736,451))
   token_base_storage.write(Uint256(574,0),(1,1,743,333,768,365))
   token_base_storage.write(Uint256(575,0),(1,1,738,366,770,400))
   token_base_storage.write(Uint256(576,0),(1,1,737,401,771,449))
   token_base_storage.write(Uint256(577,0),(1,1,673,452,703,478))
   token_base_storage.write(Uint256(578,0),(1,1,669,478,702,512))
   token_base_storage.write(Uint256(579,0),(1,1,666,523,703,553))
   token_base_storage.write(Uint256(580,0),(1,1,709,454,732,485))
   token_base_storage.write(Uint256(581,0),(1,1,703,495,731,534))
   token_base_storage.write(Uint256(582,0),(1,1,707,544,732,553))
   token_base_storage.write(Uint256(583,0),(1,1,734,457,768,478))
   token_base_storage.write(Uint256(584,0),(1,1,733,480,766,502))
   token_base_storage.write(Uint256(585,0),(1,1,738,502,770,553))
   token_base_storage.write(Uint256(586,0),(1,1,666,553,696,591))
   token_base_storage.write(Uint256(587,0),(1,1,665,596,694,628))
   token_base_storage.write(Uint256(588,0),(1,1,669,629,689,662))
   token_base_storage.write(Uint256(589,0),(1,1,708,555,734,587))
   token_base_storage.write(Uint256(590,0),(1,1,698,591,735,619))
   token_base_storage.write(Uint256(591,0),(1,1,696,636,733,662))
   token_base_storage.write(Uint256(592,0),(1,1,735,553,765,578))
   token_base_storage.write(Uint256(593,0),(1,1,739,578,770,620))
   token_base_storage.write(Uint256(594,0),(1,1,741,626,771,666))
   token_base_storage.write(Uint256(595,0),(1,1,772,335,807,362))
   token_base_storage.write(Uint256(596,0),(1,1,778,362,806,396))
   token_base_storage.write(Uint256(597,0),(1,1,775,397,809,439))
   token_base_storage.write(Uint256(598,0),(1,1,809,330,838,355))
   token_base_storage.write(Uint256(599,0),(1,1,810,356,842,389))
   token_base_storage.write(Uint256(600,0),(1,1,810,392,847,432))

	return()
end


func initial_token_base_4_internal{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}():

   token_base_storage.write(Uint256(601,0),(1,1,848,330,884,368))
   token_base_storage.write(Uint256(602,0),(1,1,854,370,880,394))
   token_base_storage.write(Uint256(603,0),(1,1,847,411,884,441))
   token_base_storage.write(Uint256(604,0),(1,1,772,444,800,497))
   token_base_storage.write(Uint256(605,0),(1,1,778,502,797,529))
   token_base_storage.write(Uint256(606,0),(1,1,771,531,796,548))
   token_base_storage.write(Uint256(607,0),(1,1,804,447,841,482))
   token_base_storage.write(Uint256(608,0),(1,1,800,485,841,511))
   token_base_storage.write(Uint256(609,0),(1,1,815,513,844,550))
   token_base_storage.write(Uint256(610,0),(1,1,850,444,884,488))
   token_base_storage.write(Uint256(611,0),(1,1,845,491,877,516))
   token_base_storage.write(Uint256(612,0),(1,1,846,517,882,556))
   token_base_storage.write(Uint256(613,0),(1,1,776,557,803,582))
   token_base_storage.write(Uint256(614,0),(1,1,777,581,806,623))
   token_base_storage.write(Uint256(615,0),(1,1,771,628,805,665))
   token_base_storage.write(Uint256(616,0),(1,1,806,556,843,583))
   token_base_storage.write(Uint256(617,0),(1,1,814,585,838,623))
   token_base_storage.write(Uint256(618,0),(1,1,811,622,843,662))
   token_base_storage.write(Uint256(619,0),(1,1,843,563,884,594))
   token_base_storage.write(Uint256(620,0),(1,1,850,594,884,625))
   token_base_storage.write(Uint256(621,0),(1,1,843,630,885,657))
   token_base_storage.write(Uint256(622,0),(1,1,886,333,915,369))
   token_base_storage.write(Uint256(623,0),(1,1,886,381,923,416))
   token_base_storage.write(Uint256(624,0),(1,1,890,415,926,450))
   token_base_storage.write(Uint256(625,0),(1,1,925,339,957,378))
   token_base_storage.write(Uint256(626,0),(1,1,926,388,955,425))
   token_base_storage.write(Uint256(627,0),(1,1,933,425,958,452))
   token_base_storage.write(Uint256(628,0),(1,1,959,337,995,367))
   token_base_storage.write(Uint256(629,0),(1,1,969,380,998,409))
   token_base_storage.write(Uint256(630,0),(1,1,959,411,996,448))
   token_base_storage.write(Uint256(631,0),(1,1,887,459,915,484))
   token_base_storage.write(Uint256(632,0),(1,1,892,486,915,524))
   token_base_storage.write(Uint256(633,0),(1,1,891,529,917,543))
   token_base_storage.write(Uint256(634,0),(1,1,917,460,947,480))
   token_base_storage.write(Uint256(635,0),(1,1,920,489,952,509))
   token_base_storage.write(Uint256(636,0),(1,1,918,508,954,542))
   token_base_storage.write(Uint256(637,0),(1,1,955,452,986,479))
   token_base_storage.write(Uint256(638,0),(1,1,954,483,999,505))
   token_base_storage.write(Uint256(639,0),(1,1,953,518,994,546))
   token_base_storage.write(Uint256(640,0),(1,1,887,553,915,574))
   token_base_storage.write(Uint256(641,0),(1,1,889,575,916,602))
   token_base_storage.write(Uint256(642,0),(1,1,887,607,915,664))
   token_base_storage.write(Uint256(643,0),(1,1,917,549,963,579))
   token_base_storage.write(Uint256(644,0),(1,1,920,595,964,631))
   token_base_storage.write(Uint256(645,0),(1,1,921,641,964,663))
   token_base_storage.write(Uint256(646,0),(1,1,967,547,993,601))
   token_base_storage.write(Uint256(647,0),(1,1,964,601,998,638))
   token_base_storage.write(Uint256(648,0),(1,1,965,645,998,665))
   token_base_storage.write(Uint256(649,0),(1,1,665,670,708,712))
   token_base_storage.write(Uint256(650,0),(1,1,666,712,700,742))
   token_base_storage.write(Uint256(651,0),(1,1,675,743,704,775))
   token_base_storage.write(Uint256(652,0),(1,1,710,669,734,709))
   token_base_storage.write(Uint256(653,0),(1,1,715,711,741,745))
   token_base_storage.write(Uint256(654,0),(1,1,713,749,741,780))
   token_base_storage.write(Uint256(655,0),(1,1,743,672,781,710))
   token_base_storage.write(Uint256(656,0),(1,1,742,717,779,760))
   token_base_storage.write(Uint256(657,0),(1,1,754,760,777,786))
   token_base_storage.write(Uint256(658,0),(1,1,667,792,696,814))
   token_base_storage.write(Uint256(659,0),(1,1,677,814,697,846))
   token_base_storage.write(Uint256(660,0),(1,1,673,854,699,876))
   token_base_storage.write(Uint256(661,0),(1,1,703,786,736,819))
   token_base_storage.write(Uint256(662,0),(1,1,699,820,733,849))
   token_base_storage.write(Uint256(663,0),(1,1,703,860,737,875))
   token_base_storage.write(Uint256(664,0),(1,1,738,796,778,824))
   token_base_storage.write(Uint256(665,0),(1,1,744,827,779,851))
   token_base_storage.write(Uint256(666,0),(1,1,739,854,768,869))
   token_base_storage.write(Uint256(667,0),(1,1,666,881,705,908))
   token_base_storage.write(Uint256(668,0),(1,1,665,911,705,939))
   token_base_storage.write(Uint256(669,0),(1,1,683,939,699,995))
   token_base_storage.write(Uint256(670,0),(1,1,711,884,742,916))
   token_base_storage.write(Uint256(671,0),(1,1,713,923,741,966))
   token_base_storage.write(Uint256(672,0),(1,1,706,967,735,988))
   token_base_storage.write(Uint256(673,0),(1,1,742,877,780,910))
   token_base_storage.write(Uint256(674,0),(1,1,748,911,781,969))
   token_base_storage.write(Uint256(675,0),(1,1,743,969,776,995))
   token_base_storage.write(Uint256(676,0),(1,1,787,668,814,691))
   token_base_storage.write(Uint256(677,0),(1,1,782,693,810,723))
   token_base_storage.write(Uint256(678,0),(1,1,781,726,812,785))
   token_base_storage.write(Uint256(679,0),(1,1,814,668,837,704))
   token_base_storage.write(Uint256(680,0),(1,1,815,704,840,749))
   token_base_storage.write(Uint256(681,0),(1,1,819,749,838,787))
   token_base_storage.write(Uint256(682,0),(1,1,844,668,886,702))
   token_base_storage.write(Uint256(683,0),(1,1,856,704,887,749))
   token_base_storage.write(Uint256(684,0),(1,1,845,754,886,790))
   token_base_storage.write(Uint256(685,0),(1,1,781,793,813,827))
   token_base_storage.write(Uint256(686,0),(1,1,782,830,821,873))
   token_base_storage.write(Uint256(687,0),(1,1,783,876,813,898))
   token_base_storage.write(Uint256(688,0),(1,1,821,802,856,821))
   token_base_storage.write(Uint256(689,0),(1,1,822,827,848,873))
   token_base_storage.write(Uint256(690,0),(1,1,823,875,852,903))
   token_base_storage.write(Uint256(691,0),(1,1,863,793,885,820))
   token_base_storage.write(Uint256(692,0),(1,1,859,820,882,848))
   token_base_storage.write(Uint256(693,0),(1,1,860,849,887,906))
   token_base_storage.write(Uint256(694,0),(1,1,781,905,816,931))
   token_base_storage.write(Uint256(695,0),(1,1,784,931,814,954))
   token_base_storage.write(Uint256(696,0),(1,1,783,960,812,989))
   token_base_storage.write(Uint256(697,0),(1,1,818,910,839,940))
   token_base_storage.write(Uint256(698,0),(1,1,820,942,845,967))
   token_base_storage.write(Uint256(699,0),(1,1,836,970,848,996))
   token_base_storage.write(Uint256(700,0),(1,1,849,905,877,931))
   token_base_storage.write(Uint256(701,0),(1,1,854,942,888,955))
   token_base_storage.write(Uint256(702,0),(1,1,849,958,878,992))
   token_base_storage.write(Uint256(703,0),(1,1,889,667,915,689))
   token_base_storage.write(Uint256(704,0),(1,1,888,690,918,731))
   token_base_storage.write(Uint256(705,0),(1,1,894,733,923,770))
   token_base_storage.write(Uint256(706,0),(1,1,925,681,955,716))
   token_base_storage.write(Uint256(707,0),(1,1,931,719,955,730))
   token_base_storage.write(Uint256(708,0),(1,1,924,740,955,769))
   token_base_storage.write(Uint256(709,0),(1,1,956,670,997,702))
   token_base_storage.write(Uint256(710,0),(1,1,960,705,994,730))
   token_base_storage.write(Uint256(711,0),(1,1,957,733,990,759))
   token_base_storage.write(Uint256(712,0),(1,1,888,769,930,798))
   token_base_storage.write(Uint256(713,0),(1,1,888,800,924,843))
   token_base_storage.write(Uint256(714,0),(1,1,889,852,925,888))
   token_base_storage.write(Uint256(715,0),(1,1,930,770,953,796))
   token_base_storage.write(Uint256(716,0),(1,1,930,799,957,852))
   token_base_storage.write(Uint256(717,0),(1,1,931,853,960,887))
   token_base_storage.write(Uint256(718,0),(1,1,959,780,987,820))
   token_base_storage.write(Uint256(719,0),(1,1,959,832,995,862))
   token_base_storage.write(Uint256(720,0),(1,1,960,864,994,887))
   token_base_storage.write(Uint256(721,0),(1,1,889,890,929,919))
   token_base_storage.write(Uint256(722,0),(1,1,888,923,928,943))
   token_base_storage.write(Uint256(723,0),(1,1,889,958,931,995))
   token_base_storage.write(Uint256(724,0),(1,1,931,889,965,902))
   token_base_storage.write(Uint256(725,0),(1,1,933,902,968,931))
   token_base_storage.write(Uint256(726,0),(1,1,931,933,968,993))
   token_base_storage.write(Uint256(727,0),(1,1,972,901,998,922))
   token_base_storage.write(Uint256(728,0),(1,1,968,924,992,959))
   token_base_storage.write(Uint256(729,0),(1,1,969,963,998,993))

	return()
end