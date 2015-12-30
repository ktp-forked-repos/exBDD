defprotocol ExBDD.Base do

  # variables

  @spec by_name(any, String.t) :: ExBDD.nid | nil
  def by_name(ref, name)

  @spec new_var(any, String.t) :: ExBDD.nid
  def new_var(ref, name)

  # clean bdd nodes:

  @spec get_nid(any, ExBDD.bdd) :: ExBDD.nid
  def get_nid(ref, bdd)

  @spec get_bdd(any, ExBDD.nid) :: ExBDD.bdd
  def get_bdd(ref, nid)

  # memos for intermediate if/then/else calls:

  @spec put_memo(any, ExBDD.bdd, ExBDD.nid) :: ExBDD.nid
  def put_memo(ref, bdd, nid)

  @spec get_memo(any, ExBDD.nid, ExBDD.nid, ExBDD.nid) :: ExBDD.nid | nil
  def get_memo(ref, f, g, h)

  # general status report
  @spec stats(any) :: [any]
  def stats(ref)

end
