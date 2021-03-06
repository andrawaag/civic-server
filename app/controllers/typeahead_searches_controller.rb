class TypeaheadSearchesController < ApplicationController
  actions_without_auth :variants

  def variants
    search_term = "%#{params[:query]}%"
    variants = Variant.eager_load(:gene)
        .where("genes.name || variants.name ILIKE ?", search_term)
        .page(params[:page])
        .per(params[:count])

    render json: PaginatedCollectionPresenter.new(
      variants,
      request,
      VariantMinimalPresenter,
      PaginationPresenter
    )
  end
end
